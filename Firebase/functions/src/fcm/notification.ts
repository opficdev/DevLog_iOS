import { onTaskDispatched } from "firebase-functions/v2/tasks";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// Cloud Tasks에 의해 트리거되는 함수
export const sendPushNotification = onTaskDispatched({
        region: "asia-northeast3",
        retryConfig: { maxAttempts: 3, minBackoffSeconds: 5 },
        rateLimits: { maxDispatchesPerSecond: 200 },
    },
    async (req) => {
        const {
            userId,
            todoId,
            todoKind,
            dueDateKey,
            title,
            body
        } = req.data ?? {};

        if (
            typeof userId !== "string" ||
            typeof todoId !== "string" ||
            typeof todoKind !== "string" ||
            typeof dueDateKey !== "string" ||
            typeof title !== "string" ||
            typeof body !== "string"
        ) {
            logger.warn("유효하지 않은 푸시 알림 payload", req.data);
            return;
        }

        try {
            const settingsDoc = await admin.firestore().doc(`users/${userId}/userData/settings`).get();
            const allowPushNotification = settingsDoc.data()?.allowPushNotification ?? true;
            if (!allowPushNotification) {
                return;
            }

            const notificationDocId = `${todoId}_${dueDateKey}`;
            const notificationDocRef = admin.firestore().doc(`users/${userId}/notifications/${notificationDocId}`);
            const alreadySentDoc = await notificationDocRef.get();
            if (alreadySentDoc.exists) {
                return;
            }

            const notificationData = {
                title: "Todo 알림",
                body,
                receivedAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                todoID: todoId,
                todoKind: todoKind
            };
            await notificationDocRef.set(notificationData);

            // 1. 사용자 FCM 토큰 가져오기
            const tokenDoc = await admin.firestore().doc(`users/${userId}/userData/tokens`).get();
            const fcmToken = tokenDoc.data()?.fcmToken;

            if (!fcmToken) {
                logger.warn(`사용자 ${userId}의 fcmToken이 없어 푸시 발송은 건너뜁니다. Firestore에는 기록했습니다.`);
                return;
            }

            // 2. 푸시 알림 발송
            const message = {
                notification: { title, body },
                data: {
                    todoID: todoId,
                    todoId: todoId,
                    todoKind: todoKind
                },
                apns: { payload: { aps: { sound: "default" } } },
                token: fcmToken,
            };
            try {
                await admin.messaging().send(message);
            } catch (sendError) {
                logger.warn(`[${userId}] 푸시 발송 실패. Firestore 기록은 유지됩니다.`, sendError);
                return;
            }

        } catch (error) {
            logger.error(`[${userId}]에게 알림 발송 중 오류 발생:`, error);
        }
    }
);
