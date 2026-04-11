import { onTaskDispatched } from "firebase-functions/v2/tasks";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { formatDateKey, toDate } from "../common/date";
import { toError } from "../common/error";
import { FirestorePath } from "../common/firestorePath";
import { resolveTimeZone } from "./shared";

type TaskPayload = {
    userId: string;
    todoId: string;
    dueDateKey: string;
    title: string;
    body: string;
};

type FirestoreErrorLike = {
    code?: unknown;
};

// 큐에 적재된 알림 payload 검증 및 실제 푸시 발송 수행
export const sendPushNotification = onTaskDispatched({
        maxInstances: 10,
        region: "asia-northeast3",
        retryConfig: { maxAttempts: 3, minBackoffSeconds: 5 },
        rateLimits: { maxDispatchesPerSecond: 10 },
    },
    async (req) => {
        const parsed = parseTaskPayload(req.data);
        if (!parsed) {
            logger.warn("유효하지 않은 푸시 알림 payload", req.data);
            return;
        }

        try {
            const { userId, todoId, dueDateKey, title, body } = parsed;

            const settingsDocRef = admin.firestore()
                .doc(FirestorePath.userData(userId, FirestorePath.UserDataDocument.settings));
            const todoDocRef = admin.firestore().doc(FirestorePath.todo(userId, todoId));
            const [settingsDoc, todoDoc] = await Promise.all([
                settingsDocRef.get(),
                todoDocRef.get()
            ]);
            const settingsData = settingsDoc.data();
            const allowPushNotification = settingsData?.allowPushNotification ?? true;
            if (!allowPushNotification) { return; }

            const todoData = todoDoc.data();
            if (!todoDoc.exists || !todoData || todoData.isCompleted === true) { return; }
            const todoCategory = typeof todoData.category === "string" ? todoData.category.trim() : "";
            if (!todoCategory) { return; }

            const timeZone = resolveTimeZone(settingsData);

            const currentDueDate = toDate(todoData.dueDate);
            if (!currentDueDate) { return; }
            if (formatDateKey(currentDueDate, timeZone) !== dueDateKey) { return; }

            const id = `${todoId}_${dueDateKey}`;
            const dispatchDocRef = admin.firestore().doc(FirestorePath.notificationDispatch(userId, id));
            const notificationDocRef = admin.firestore().doc(FirestorePath.notification(userId, id));

            try {
                await dispatchDocRef.create({
                    todoId,
                    dueDateKey
                });
            } catch (error) {
                if (isAlreadyExistsError(error)) {
                    return;
                }
                throw error;
            }

            const notificationData = {
                title: "Todo 알림",
                body,
                receivedAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                isDeleted: false,
                todoId: todoId,
                todoCategory: todoCategory
            };
            await notificationDocRef.set(notificationData, { merge: true });

            // 1. 사용자 FCM 토큰과 읽지 않은 알림 수 가져오기
            const unreadCountPromise = admin.firestore()
                .collection(FirestorePath.notifications(userId))
                .where("isRead", "==", false)
                .count()
                .get();
            // 2. 사용자 FCM 토큰 가져오기
            const tokenDocPromise = admin.firestore()
                .doc(FirestorePath.userData(userId, FirestorePath.UserDataDocument.tokens))
                .get();
            const [tokenDoc, unreadCountSnapshot] = await Promise.all([
                tokenDocPromise,
                unreadCountPromise
            ]);
            const fcmToken = tokenDoc.data()?.fcmToken;
            const unreadNotificationCount = unreadCountSnapshot.data().count;

            if (!fcmToken) {
                logger.warn(`사용자 ${userId}의 fcmToken이 없어 푸시 발송은 건너뜁니다. Firestore에는 기록했습니다.`);
                return;
            }

            // 2. 푸시 알림 발송
            const message = {
                notification: { title, body },
                data: {
                    todoId: todoId,
                    todoCategory: todoCategory
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                            badge: unreadNotificationCount
                        }
                    }
                },
                token: fcmToken,
            };
            try {
                await admin.messaging().send(message);
            } catch (sendError) {
                logger.warn(`[${userId}] 푸시 발송 실패. Firestore 기록은 유지됩니다.`, sendError);
                return;
            }

        } catch (error) {
            logger.error("알림 발송 중 오류 발생", toError(error), {
                payload: req.data
            });
        }
    }
);

// 큐 payload의 발송 필수 필드 충족 여부 검증
function parseTaskPayload(data: FirebaseFirestore.DocumentData | undefined): TaskPayload | null {
    const {
        userId,
        todoId,
        dueDateKey,
        title,
        body
    } = data ?? {};

    if (
        typeof userId !== "string" ||
        typeof todoId !== "string" ||
        typeof dueDateKey !== "string" ||
        typeof title !== "string" ||
        typeof body !== "string"
    ) {
        return null;
    }

    if (userId.includes("/") || todoId.includes("/")) {
        return null;
    }

    return {
        userId,
        todoId,
        dueDateKey,
        title,
        body
    };
}

// Firestore create 충돌의 기존 문서 존재 여부 판별
function isAlreadyExistsError(error: unknown): boolean {
    const code = (error as FirestoreErrorLike)?.code;
    return code === 6 || code === "6" || code === "already-exists";
}
