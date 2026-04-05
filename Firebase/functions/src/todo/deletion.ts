import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { FirestorePath } from "../common/firestorePath";
import {toError} from "../common/error";

const LOCATION = "asia-northeast3";
const QUERY_BATCH_SIZE = 200;

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
                deletedAt: admin.firestore.FieldValue.serverTimestamp(),
                isDeleting: admin.firestore.FieldValue.delete(),
                isDeleted: admin.firestore.FieldValue.delete()
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
            const currentTodoSnapshot = await todoRef.get();

            if (currentTodoSnapshot.exists && !currentTodoSnapshot.data()?.deletedAt) {
                await todoRef.update({
                    deletedAt: null,
                    isDeleting: admin.firestore.FieldValue.delete(),
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

            if (todoSnapshot.exists && !!todoSnapshot.data()?.deletedAt) {
                await todoRef.update({
                    deletedAt: null,
                    isDeleting: admin.firestore.FieldValue.delete(),
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
