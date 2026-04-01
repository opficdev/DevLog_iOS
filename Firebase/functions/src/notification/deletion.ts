import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onTaskDispatched } from "firebase-functions/v2/tasks";
import { getFunctions } from "firebase-admin/functions";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { normalizeError } from "../common/error";
import { FirestorePath } from "../common/firestorePath";

const LOCATION = "asia-northeast3";
const DELETE_DELAY_SECONDS = 5;

type NotificationDeletionTaskData = {
    userId: string;
    notificationId: string;
    createdAt?: FirebaseFirestore.Timestamp | Date | null;
};

export const requestPushNotificationDeletion = onCall({
        cors: true,
        maxInstances: 3,
        region: LOCATION,
    },
    async (request) => {
        const userId = request.auth?.uid;
        const notificationId = typeof request.data?.notificationId === "string" ?
            request.data.notificationId.trim() :
            "";

        if (!userId) {
            throw new HttpsError("unauthenticated", "인증된 사용자가 아닙니다.");
        }

        if (!notificationId) {
            throw new HttpsError("invalid-argument", "notificationId가 필요합니다.");
        }

        const notificationRef = admin.firestore().doc(FirestorePath.notification(userId, notificationId));
        const notificationSnapshot = await notificationRef.get();

        if (!notificationSnapshot.exists) {
            throw new HttpsError("not-found", "Notification을 찾을 수 없습니다.");
        }

        const taskRef = admin.firestore().collection("notificationDeletionTasks").doc();
        const taskData = {
            userId,
            notificationId,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        };

        try {
            await taskRef.set(taskData);
            await notificationRef.set({
                // deletingAt: 삭제 요청은 되었지만, 5초 유예 후 최종 삭제되기 전 상태를 의미한다.
                deletingAt: admin.firestore.FieldValue.serverTimestamp()
            }, {merge: true});

            const queue = getFunctions().taskQueue(
                `locations/${LOCATION}/functions/completePushNotificationDeletion`
            );
            await queue.enqueue(
                {taskId: taskRef.id},
                {scheduleDelaySeconds: DELETE_DELAY_SECONDS}
            );
        } catch (error) {
            try {
                await taskRef.delete();
            } catch (cleanupError) {
                logger.warn("notificationDeletionTasks 정리 실패", {
                    userId,
                    notificationId,
                    taskId: taskRef.id,
                    error: normalizeError(cleanupError)
                });
            }

            const currentNotificationSnapshot = await notificationRef.get();
            if (currentNotificationSnapshot.exists) {
                await notificationRef.update({
                    deletingAt: admin.firestore.FieldValue.delete()
                });
            }

            logger.error("푸시 알림 삭제 요청 실패", {
                userId,
                notificationId,
                error: normalizeError(error)
            });
            throw new HttpsError("internal", "푸시 알림 삭제 요청에 실패했습니다.");
        }

        return {success: true};
    }
);

export const undoPushNotificationDeletion = onCall({
        cors: true,
        maxInstances: 3,
        region: LOCATION,
    },
    async (request) => {
        const userId = request.auth?.uid;
        const notificationId = typeof request.data?.notificationId === "string" ?
            request.data.notificationId.trim() :
            "";

        if (!userId) {
            throw new HttpsError("unauthenticated", "인증된 사용자가 아닙니다.");
        }

        if (!notificationId) {
            throw new HttpsError("invalid-argument", "notificationId가 필요합니다.");
        }

        const taskSnapshot = await admin.firestore()
            .collection("notificationDeletionTasks")
            .where("userId", "==", userId)
            .where("notificationId", "==", notificationId)
            .get();
        const notificationRef = admin.firestore().doc(FirestorePath.notification(userId, notificationId));

        try {
            const notificationSnapshot = await notificationRef.get();
            if (notificationSnapshot.exists) {
                await notificationRef.update({
                    deletingAt: admin.firestore.FieldValue.delete()
                });
            }

            if (!taskSnapshot.empty) {
                const batch = admin.firestore().batch();
                taskSnapshot.docs.forEach((document) => {
                    batch.delete(document.ref);
                });
                await batch.commit();
            }
        } catch (error) {
            logger.error("푸시 알림 삭제 취소 실패", {
                userId,
                notificationId,
                error: normalizeError(error)
            });
            throw new HttpsError("internal", "푸시 알림 삭제 취소에 실패했습니다.");
        }

        return {success: true};
    }
);

export const completePushNotificationDeletion = onTaskDispatched({
        maxInstances: 1,
        region: LOCATION,
        retryConfig: {maxAttempts: 3, minBackoffSeconds: 5},
        rateLimits: {maxDispatchesPerSecond: 200},
    },
    async (request) => {
        const taskId = typeof request.data?.taskId === "string" ? request.data.taskId.trim() : "";
        if (!taskId) {
            logger.warn("유효하지 않은 푸시 알림 삭제 payload", request.data);
            return;
        }

        const taskRef = admin.firestore().collection("notificationDeletionTasks").doc(taskId);
        const taskSnapshot = await taskRef.get();
        if (!taskSnapshot.exists) { return; }

        const taskData = taskSnapshot.data() as NotificationDeletionTaskData | undefined;
        const userId = typeof taskData?.userId === "string" ? taskData.userId : "";
        const notificationId = typeof taskData?.notificationId === "string" ? taskData.notificationId : "";
        if (!userId || !notificationId) {
            logger.warn("notificationDeletionTasks 문서 형식이 올바르지 않습니다.", {taskId});
            return;
        }

        const notificationRef = admin.firestore().doc(FirestorePath.notification(userId, notificationId));

        try {
            const notificationSnapshot = await notificationRef.get();
            const deletingAt = notificationSnapshot.data()?.deletingAt;

            if (!notificationSnapshot.exists || !deletingAt) {
                await taskRef.delete();
                return;
            }

            await notificationRef.delete();
            await taskRef.delete();
        } catch (error) {
            logger.error("푸시 알림 최종 삭제 실패", {
                userId,
                notificationId,
                taskId,
                error: normalizeError(error)
            });
            throw error;
        }
    }
);
