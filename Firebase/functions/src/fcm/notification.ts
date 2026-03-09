import { onTaskDispatched } from "firebase-functions/v2/tasks";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { resolveTimeZone } from "./shared";

type TaskPayload = {
    userId: string;
    todoId: string;
    todoKind: string;
    dueDateKey: string;
    title: string;
    body: string;
};

type FirestoreErrorLike = {
    code?: unknown;
};

// Cloud Tasks에 의해 트리거되는 함수
export const sendPushNotification = onTaskDispatched({
        region: "asia-northeast3",
        retryConfig: { maxAttempts: 3, minBackoffSeconds: 5 },
        rateLimits: { maxDispatchesPerSecond: 200 },
    },
    async (req) => {
        const taskId = req.data?.taskId;
        if (!isValidTaskId(taskId)) {
            logger.warn("유효하지 않은 푸시 알림 payload", req.data);
            return;
        }

        const taskDocRef = admin.firestore().collection("notificationTasks").doc(taskId);
        try {
            const taskDoc = await taskDocRef.get();
            if (!taskDoc.exists) {
                logger.warn("notificationTask 문서를 찾을 수 없습니다.", { taskId });
                return;
            }

            const parsed = parseTaskPayload(taskDoc.data());
            if (!parsed) {
                logger.warn("notificationTask 문서 형식이 올바르지 않습니다.", { taskId });
                return;
            }
            const { userId, todoId, todoKind, dueDateKey, title, body } = parsed;

            const settingsDocRef = admin.firestore().doc(`users/${userId}/userData/settings`);
            const todoDocRef = admin.firestore().doc(`users/${userId}/todoLists/${todoId}`);
            const [settingsDoc, todoDoc] = await Promise.all([
                settingsDocRef.get(),
                todoDocRef.get()
            ]);
            const settingsData = settingsDoc.data();
            const allowPushNotification = settingsData?.allowPushNotification ?? true;
            if (!allowPushNotification) { return; }

            const todoData = todoDoc.data();
            if (!todoDoc.exists || !todoData || todoData.isCompleted === true) { return; }

            const timeZone = resolveTimeZone(settingsData);

            const dueDateValue = todoData.dueDate;
            const currentDueDate = dueDateValue instanceof admin.firestore.Timestamp ?
                dueDateValue.toDate() :
                dueDateValue instanceof Date ?
                    dueDateValue :
                    null;
            if (!currentDueDate) { return; }
            if (formatDateKey(currentDueDate, timeZone) !== dueDateKey) { return; }

            const id = `${todoId}_${dueDateKey}`;
            const receiptDocRef = admin.firestore().doc(
                `users/${userId}/notificationReceipts/${id}`
            );
            const notificationDocRef = admin.firestore().doc(`users/${userId}/notifications/${id}`);

            try {
                await receiptDocRef.create({
                    todoId,
                    dueDateKey,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
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
                todoId: todoId,
                todoKind: todoKind
            };
            await notificationDocRef.set(notificationData, { merge: true });

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
            logger.error("알림 발송 중 오류 발생", {
                taskId,
                error
            });
        } finally {
            try {
                await taskDocRef.delete();
            } catch (cleanupError) {
                logger.warn("notificationTask 정리 실패", {
                    taskId,
                    cleanupError
                });
            }
        }
    }
);

function isValidTaskId(value: unknown): value is string {
    return typeof value === "string" && /^[A-Za-z0-9_-]{1,128}$/.test(value);
}

function parseTaskPayload(data: FirebaseFirestore.DocumentData | undefined): TaskPayload | null {
    const {
        userId,
        todoId,
        todoKind,
        dueDateKey,
        title,
        body
    } = data ?? {};

    if (
        typeof userId !== "string" ||
        typeof todoId !== "string" ||
        typeof todoKind !== "string" ||
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
        todoKind,
        dueDateKey,
        title,
        body
    };
}

function isAlreadyExistsError(error: unknown): boolean {
    const code = (error as FirestoreErrorLike)?.code;
    return code === 6 || code === "6" || code === "already-exists";
}

function formatDateKey(date: Date, timeZone: string): string {
    const parts = new Intl.DateTimeFormat("en-US", {
        timeZone,
        year: "numeric",
        month: "2-digit",
        day: "2-digit"
    }).formatToParts(date);

    const partMap = new Map(parts.map(p => [p.type, p.value]));
    const year = partMap.get("year");
    const month = partMap.get("month");
    const day = partMap.get("day");

    if (!year || !month || !day) {
        logger.warn("formatDateKey 파트 추출 실패", {
            date: date.toISOString(),
            timeZone,
            parts
        });
    }

    return `${year ?? "1970"}-${month ?? "01"}-${day ?? "01"}`;
}
