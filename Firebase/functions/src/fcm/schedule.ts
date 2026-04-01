import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFunctions } from "firebase-admin/functions";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { addDays, getZonedParts, zonedDateTimeToUTC } from "../common/date";
import { normalizeError } from "../common/error";
import { FirestorePath } from "../common/firestorePath";
import { resolveTimeZone } from "./shared";

const LOCATION = "asia-northeast3";
const DEFAULT_HOUR = 9;
const DEFAULT_MINUTE = 0;
const MINUTE_INTERVAL = 5;

// 사용자별 설정 시간에 맞춘 내일 마감 Todo 알림 작업 큐 적재
export const scheduleTodoReminder = onSchedule({
        maxInstances: 1,
        region: LOCATION,
        schedule: "*/5 * * * *",
        timeZone: "UTC"
    },
    async (event) => {
        try {
            const now = event.scheduleTime ? new Date(event.scheduleTime) : new Date();
            const queue = getFunctions().taskQueue(`locations/${LOCATION}/functions/sendPushNotification`);
            let usersSnapshot: FirebaseFirestore.QuerySnapshot<FirebaseFirestore.DocumentData>;
            try {
                usersSnapshot = await admin.firestore().collection("users").get();
            } catch (error) {
                logger.error("users 조회 실패", {
                    at: "collection(users).get()",
                    ...normalizeError(error)
                });
                return;
            }

            for (const userDoc of usersSnapshot.docs) {
                const userId = userDoc.id;
                let settingsDoc: FirebaseFirestore.DocumentSnapshot<FirebaseFirestore.DocumentData>;
                try {
                    settingsDoc = await admin.firestore()
                        .doc(FirestorePath.userData(userId, FirestorePath.UserDataDocument.settings))
                        .get();
                } catch (error) {
                    logger.error("settings 조회 실패", {
                        userId,
                        at: "users/{uid}/userData/settings",
                        ...normalizeError(error)
                    });
                    continue;
                }
                const settings = settingsDoc.data();
                if (!settings || settings.allowPushNotification !== true) { continue; }

                const hour = Number.isInteger(settings.pushNotificationHour) ? settings.pushNotificationHour : DEFAULT_HOUR;
                const configuredMinute = Number.isInteger(settings.pushNotificationMinute) ?
                    Number(settings.pushNotificationMinute) :
                    DEFAULT_MINUTE;
                const minute = configuredMinute < 0 || configuredMinute > 59 ?
                    DEFAULT_MINUTE :
                    configuredMinute - (configuredMinute % MINUTE_INTERVAL);

                const timeZone = resolveTimeZone(settings);

                const localNow = getZonedParts(now, timeZone);
                if (localNow.hour !== hour) { continue; }
                const windowEnd = Math.min(minute + MINUTE_INTERVAL, 60);
                if (localNow.minute < minute || localNow.minute >= windowEnd) { continue; }

                const tomorrow = addDays(localNow.year, localNow.month, localNow.day, 1);
                const dayAfterTomorrow = addDays(localNow.year, localNow.month, localNow.day, 2);
                const startUTC = zonedDateTimeToUTC(
                    tomorrow.year,
                    tomorrow.month,
                    tomorrow.day,
                    0, 0,
                    timeZone
                );
                const endUTC = zonedDateTimeToUTC(
                    dayAfterTomorrow.year,
                    dayAfterTomorrow.month,
                    dayAfterTomorrow.day,
                    0, 0,
                    timeZone
                );

                const dueDateKey = `${tomorrow.year}-${tomorrow.month.toString().padStart(2, "0")}-${tomorrow.day.toString().padStart(2, "0")}`;
                let todosSnapshot: FirebaseFirestore.QuerySnapshot<FirebaseFirestore.DocumentData>;
                try {
                    todosSnapshot = await admin.firestore()
                        .collection(FirestorePath.todos(userId))
                        .where("dueDate", ">=", admin.firestore.Timestamp.fromDate(startUTC))
                        .where("dueDate", "<", admin.firestore.Timestamp.fromDate(endUTC))
                        .get();
                } catch (error) {
                    logger.error("todoLists 조회 실패", {
                        userId,
                        at: "todoLists.where(dueDate>=start).where(dueDate<end)",
                        startUTC: startUTC.toISOString(),
                        endUTC: endUTC.toISOString(),
                        dueDateKey,
                        ...normalizeError(error)
                    });
                    continue;
                }

                for (const todoDoc of todosSnapshot.docs) {
                    const todoData = todoDoc.data();
                    const todoTitle = typeof todoData.title === "string" && todoData.title.trim() ?
                        todoData.title :
                        "제목 없음";

                    const notificationPayload = {
                        userId,
                        todoId: todoDoc.id,
                        dueDateKey,
                        title: "DevLog",
                        body: `'${todoTitle}'의 마감일이 내일입니다.`
                    };

                    try {
                        await queue.enqueue(notificationPayload);
                    } catch (error) {
                        logger.error("Cloud Tasks enqueue 실패", {
                            userId,
                            todoId: todoDoc.id,
                            dueDateKey,
                            ...normalizeError(error)
                        });
                    }
                }
            }

        } catch (error) {
            logger.error("알림 스케줄 배치 실행 중 오류 발생", normalizeError(error));
        }
    }
);
