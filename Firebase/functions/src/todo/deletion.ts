import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onTaskDispatched} from "firebase-functions/v2/tasks";
import {getFunctions} from "firebase-admin/functions";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { FirestorePath } from "../common/firestorePath";
import {toError} from "../common/error";

const LOCATION = "asia-northeast3";
const DELETE_DELAY_SECONDS = 5;
const QUERY_BATCH_SIZE = 200;

type TodoDeletionPayload = {
    userId: string;
    todoId: string;
};

export const requestTodoDeletion = onCall({
        cors: true,
        maxInstances: 3,
        region: LOCATION,
    },
    async (request) => {
        const userId = request.auth?.uid;
        const todoId = typeof request.data?.todoId === "string" ? request.data.todoId.trim() : "";

        if (!userId) {
            throw new HttpsError("unauthenticated", "인증된 사용자가 아닙니다.");
        }

        if (!todoId) {
            throw new HttpsError("invalid-argument", "todoId가 필요합니다.");
        }

        const todoRef = admin.firestore().doc(FirestorePath.todo(userId, todoId));
        const todoSnapshot = await todoRef.get();

        if (!todoSnapshot.exists || todoSnapshot.data()?.deletedAt) {
            throw new HttpsError("not-found", "Todo를 찾을 수 없습니다.");
        }

        try {
            await todoRef.set({
                isDeleting: true,
                deletedAt: admin.firestore.FieldValue.delete(),
                isDeleted: admin.firestore.FieldValue.delete()
            }, {merge: true});

            await updateNotificationsDeletionState(
                userId,
                todoId,
                {
                    deletingAt: admin.firestore.FieldValue.serverTimestamp(),
                    isDeleted: false
                }
            );

            const queue = getFunctions().taskQueue(
                `locations/${LOCATION}/functions/completeTodoDeletion`
            );
            await queue.enqueue(
                { userId, todoId },
                { scheduleDelaySeconds: DELETE_DELAY_SECONDS }
            );
        } catch (error) {
            const currentTodoSnapshot = await todoRef.get();

            if (currentTodoSnapshot.exists && !currentTodoSnapshot.data()?.deletedAt) {
                await todoRef.update({
                    isDeleting: false,
                    deletedAt: admin.firestore.FieldValue.delete(),
                    isDeleted: admin.firestore.FieldValue.delete()
                });
            }

            await updateNotificationsDeletionState(
                userId,
                todoId,
                {
                    deletingAt: admin.firestore.FieldValue.delete(),
                    isDeleted: false
                }
            );

            logger.error("todo 삭제 요청 실패", toError(error), {
                userId,
                todoId
            });
            throw new HttpsError("internal", "Todo 삭제 요청에 실패했습니다.");
        }

        return {success: true};
    }
);

export const undoTodoDeletion = onCall({
        cors: true,
        maxInstances: 3,
        region: LOCATION,
    },
    async (request) => {
        const userId = request.auth?.uid;
        const todoId = typeof request.data?.todoId === "string" ? request.data.todoId.trim() : "";

        if (!userId) {
            throw new HttpsError("unauthenticated", "인증된 사용자가 아닙니다.");
        }

        if (!todoId) {
            throw new HttpsError("invalid-argument", "todoId가 필요합니다.");
        }

        try {
            const todoRef = admin.firestore().doc(FirestorePath.todo(userId, todoId));
            const todoSnapshot = await todoRef.get();

            if (todoSnapshot.exists && !todoSnapshot.data()?.deletedAt) {
                await todoRef.update({
                    isDeleting: false,
                    deletedAt: admin.firestore.FieldValue.delete(),
                    isDeleted: admin.firestore.FieldValue.delete()
                });
            }

            await updateNotificationsDeletionState(
                userId,
                todoId,
                {
                    deletingAt: admin.firestore.FieldValue.delete(),
                    isDeleted: false
                }
            );
        } catch (error) {
            logger.error("todo 삭제 취소 실패", toError(error), {
                userId,
                todoId
            });
            throw new HttpsError("internal", "Todo 삭제 취소에 실패했습니다.");
        }

        return {success: true};
    }
);

export const completeTodoDeletion = onTaskDispatched({
        maxInstances: 5,
        region: LOCATION,
        retryConfig: { maxAttempts: 3, minBackoffSeconds: 5 },
        rateLimits: { maxDispatchesPerSecond: 5 },
    },
    async (request) => {
        const payload = parseDeletionPayload(request.data);
        if (!payload) {
            logger.warn("유효하지 않은 todo 삭제 payload", request.data);
            return;
        }

            const { userId, todoId } = payload;
            const todoRef = admin.firestore().doc(FirestorePath.todo(userId, todoId));

        try {
            const todoSnapshot = await todoRef.get();
            const isDeleting = todoSnapshot.data()?.isDeleting === true;
            const isDeleted = !!todoSnapshot.data()?.deletedAt;

            if (!todoSnapshot.exists || !isDeleting || isDeleted) {
                return;
            }

            await todoRef.set({
                isDeleting: false,
                deletedAt: admin.firestore.FieldValue.serverTimestamp(),
                isDeleted: admin.firestore.FieldValue.delete(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            }, {merge: true});

            await updateNotificationsDeletionState(
                userId,
                todoId,
                {
                    deletingAt: admin.firestore.FieldValue.delete(),
                    isDeleted: true
                }
            );
        } catch (error) {
            logger.error("todo 최종 soft delete 실패", toError(error), {
                userId,
                todoId
            });
            throw error;
        }
    }
);

function parseDeletionPayload(data: unknown): TodoDeletionPayload | null {
    const userId = typeof (data as TodoDeletionPayload | undefined)?.userId === "string" ?
        (data as TodoDeletionPayload).userId.trim() :
        "";
    const todoId = typeof (data as TodoDeletionPayload | undefined)?.todoId === "string" ?
        (data as TodoDeletionPayload).todoId.trim() :
        "";

    if (!userId || !todoId) {
        return null;
    }

    return {
        userId,
        todoId
    };
}

async function updateNotificationsDeletionState(
    userId: string,
    todoId: string,
    data: { [key: string]: FirebaseFirestore.FieldValue | boolean }
): Promise<void> {
    let lastDocument: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | undefined

    while (true) {
        let query = admin.firestore()
            .collection(FirestorePath.notifications(userId))
            .where("todoId", "==", todoId)
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(QUERY_BATCH_SIZE)
        if (lastDocument) {
            query = query.startAfter(lastDocument);
        }

        const snapshot = await query.get();

        if (snapshot.empty) { return; }

        const batch = admin.firestore().batch();
        snapshot.docs.forEach((document) => {
            batch.update(document.ref, data);
        });
        await batch.commit();

        if (snapshot.size < QUERY_BATCH_SIZE) { return; }
        lastDocument = snapshot.docs[snapshot.docs.length - 1];
    }
}
