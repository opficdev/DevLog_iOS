import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onTaskDispatched } from "firebase-functions/v2/tasks";
import { getFunctions } from "firebase-admin/functions";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { toError } from "../common/error";
import { FirestorePath } from "../common/firestorePath";

const LOCATION = "asia-northeast3";
const DELETE_DELAY_SECONDS = 5;

type NotificationDeletionPayload = {
    userId: string;
    notificationId: string;
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

        if (!notificationSnapshot.exists || notificationSnapshot.data()?.isDeleted === true) {
            throw new HttpsError("not-found", "Notification을 찾을 수 없습니다.");
        }

        try {
            await notificationRef.set({
                // deletingAt: 삭제 요청은 되었지만, 5초 유예 후 최종 삭제되기 전 상태를 의미한다.
                deletingAt: admin.firestore.FieldValue.serverTimestamp(),
                isDeleted: false
            }, {merge: true});

            const queue = getFunctions().taskQueue(
                `locations/${LOCATION}/functions/completePushNotificationDeletion`
            );
            await queue.enqueue(
                { userId, notificationId },
                {scheduleDelaySeconds: DELETE_DELAY_SECONDS}
            );
        } catch (error) {
            const currentNotificationSnapshot = await notificationRef.get();
            if (currentNotificationSnapshot.exists && currentNotificationSnapshot.data()?.isDeleted !== true) {
                await notificationRef.update({
                    deletingAt: admin.firestore.FieldValue.delete()
                });
            }

            logger.error("푸시 알림 삭제 요청 실패", toError(error), {
                userId,
                notificationId
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
        const notificationRef = admin.firestore().doc(FirestorePath.notification(userId, notificationId));

        try {
            const notificationSnapshot = await notificationRef.get();
            if (notificationSnapshot.exists && notificationSnapshot.data()?.isDeleted !== true) {
                await notificationRef.update({
                    deletingAt: admin.firestore.FieldValue.delete(),
                    isDeleted: false
                });
            }
        } catch (error) {
            logger.error("푸시 알림 삭제 취소 실패", toError(error), {
                userId,
                notificationId
            });
            throw new HttpsError("internal", "푸시 알림 삭제 취소에 실패했습니다.");
        }

        return {success: true};
    }
);

export const completePushNotificationDeletion = onTaskDispatched({
        maxInstances: 5,
        region: LOCATION,
        retryConfig: { maxAttempts: 3, minBackoffSeconds: 5},
        rateLimits: { maxDispatchesPerSecond: 5 },
    },
    async (request) => {
        const payload = parseDeletionPayload(request.data);
        if (!payload) {
            logger.warn("유효하지 않은 푸시 알림 삭제 payload", request.data);
            return;
        }

        const { userId, notificationId } = payload;

        const notificationRef = admin.firestore().doc(FirestorePath.notification(userId, notificationId));

        try {
            const notificationSnapshot = await notificationRef.get();
            const deletingAt = notificationSnapshot.data()?.deletingAt;
            const isDeleted = notificationSnapshot.data()?.isDeleted === true;

            if (!notificationSnapshot.exists || !deletingAt || isDeleted) {
                return;
            }

            await notificationRef.set({
                deletingAt: admin.firestore.FieldValue.delete(),
                isDeleted: true
            }, { merge: true });
        } catch (error) {
            logger.error("푸시 알림 최종 삭제 실패", toError(error), {
                userId,
                notificationId
            });
            throw error;
        }
    }
);

function parseDeletionPayload(data: unknown): NotificationDeletionPayload | null {
    const userId = typeof (data as NotificationDeletionPayload | undefined)?.userId === "string" ?
        (data as NotificationDeletionPayload).userId.trim() :
        "";
    const notificationId = typeof (data as NotificationDeletionPayload | undefined)?.notificationId === "string" ?
        (data as NotificationDeletionPayload).notificationId.trim() :
        "";

    if (!userId || !notificationId) {
        return null;
    }

    return {
        userId,
        notificationId
    };
}
