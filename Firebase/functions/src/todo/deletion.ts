import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onTaskDispatched} from "firebase-functions/v2/tasks";
import {getFunctions} from "firebase-admin/functions";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {normalizeError} from "../common/error";

const LOCATION = "asia-northeast3";
const DELETE_DELAY_SECONDS = 5;
const QUERY_BATCH_SIZE = 200;

type TodoDeletionTaskData = {
    userId: string;
    todoId: string;
    createdAt?: FirebaseFirestore.Timestamp | Date | null;
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

        const todoRef = admin.firestore().doc(`users/${userId}/todoLists/${todoId}`);
        const todoSnapshot = await todoRef.get();

        if (!todoSnapshot.exists) {
            throw new HttpsError("not-found", "Todo를 찾을 수 없습니다.");
        }

        const taskRef = admin.firestore().collection("todoDeletionTasks").doc();
        const taskData = {
            userId,
            todoId,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        };

        try {
            await taskRef.set(taskData);
            await todoRef.set({
                // deletingAt: 삭제 요청은 되었지만, 5초 유예 후 최종 삭제되기 전 상태를 의미한다.
                deletingAt: admin.firestore.FieldValue.serverTimestamp()
            }, {merge: true});

            await updateNotificationsDeletingAt(
                userId,
                todoId,
                admin.firestore.FieldValue.serverTimestamp()
            );

            const queue = getFunctions().taskQueue(
                `locations/${LOCATION}/functions/completeTodoDeletion`
            );
            await queue.enqueue(
                {taskId: taskRef.id},
                {scheduleDelaySeconds: DELETE_DELAY_SECONDS}
            );
        } catch (error) {
            try {
                await taskRef.delete();
            } catch (cleanupError) {
                logger.warn("todoDeletionTasks 정리 실패", {
                    userId,
                    todoId,
                    taskId: taskRef.id,
                    error: normalizeError(cleanupError)
                });
            }

            const todoSnapshot = await todoRef.get();

            if (todoSnapshot.exists) {
                await todoRef.update({
                    deletingAt: admin.firestore.FieldValue.delete()
                });
            }

            await updateNotificationsDeletingAt(
                userId,
                todoId,
                admin.firestore.FieldValue.delete()
            );
            logger.error("todo 삭제 요청 실패", {
                userId,
                todoId,
                error: normalizeError(error)
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

        const taskSnapshot = await admin.firestore()
            .collection("todoDeletionTasks")
            .where("userId", "==", userId)
            .where("todoId", "==", todoId)
            .get();

        try {
            const todoRef = admin.firestore().doc(`users/${userId}/todoLists/${todoId}`);
            const todoSnapshot = await todoRef.get();

            if (todoSnapshot.exists) {
                await todoRef.update({
                    deletingAt: admin.firestore.FieldValue.delete()
                });
            }

            await updateNotificationsDeletingAt(
                userId,
                todoId,
                admin.firestore.FieldValue.delete()
            );

            if (!taskSnapshot.empty) {
                const batch = admin.firestore().batch();
                taskSnapshot.docs.forEach((document) => {
                    batch.delete(document.ref);
                });
                await batch.commit();
            }
        } catch (error) {
            logger.error("todo 삭제 취소 실패", {
                userId,
                todoId,
                error: normalizeError(error)
            });
            throw new HttpsError("internal", "Todo 삭제 취소에 실패했습니다.");
        }

        return {success: true};
    }
);

export const completeTodoDeletion = onTaskDispatched({
        maxInstances: 1,
        region: LOCATION,
        retryConfig: {maxAttempts: 3, minBackoffSeconds: 5},
        rateLimits: {maxDispatchesPerSecond: 200},
    },
    async (request) => {
        const taskId = typeof request.data?.taskId === "string" ? request.data.taskId.trim() : "";
        if (!taskId) {
            logger.warn("유효하지 않은 todo 삭제 payload", request.data);
            return;
        }

        const taskRef = admin.firestore().collection("todoDeletionTasks").doc(taskId);
        const taskSnapshot = await taskRef.get();
        if (!taskSnapshot.exists) { return; }

        const taskData = taskSnapshot.data() as TodoDeletionTaskData | undefined;
        const userId = typeof taskData?.userId === "string" ? taskData.userId : "";
        const todoId = typeof taskData?.todoId === "string" ? taskData.todoId : "";
        if (!userId || !todoId) {
            logger.warn("todoDeletionTasks 문서 형식이 올바르지 않습니다.", {taskId});
            return;
        }

        const todoRef = admin.firestore().doc(`users/${userId}/todoLists/${todoId}`);

        try {
            const todoSnapshot = await todoRef.get();
            const deletingAt = todoSnapshot.data()?.deletingAt;

            if (!todoSnapshot.exists || !deletingAt) {
                await taskRef.delete();
                return;
            }

            await todoRef.delete();
            await taskRef.delete();
        } catch (error) {
            logger.error("todo 최종 삭제 실패", {
                userId,
                todoId,
                taskId,
                error: normalizeError(error)
            });
            throw error;
        }
    }
);

async function updateNotificationsDeletingAt(
    userId: string,
    todoId: string,
    fieldValue: FirebaseFirestore.FieldValue
): Promise<void> {
    while (true) {
        const snapshot = await admin.firestore()
            .collection(`users/${userId}/notifications`)
            .where("todoId", "==", todoId)
            .limit(QUERY_BATCH_SIZE)
            .get();

        if (snapshot.empty) { return; }

        const batch = admin.firestore().batch();
        snapshot.docs.forEach((document) => {
            batch.update(document.ref, {
                deletingAt: fieldValue
            });
        });
        await batch.commit();

        if (snapshot.size < QUERY_BATCH_SIZE) { return; }
    }
}
