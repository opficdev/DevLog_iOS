import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFunctions } from "firebase-admin/functions";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const LOCATION = "asia-northeast3";
const DEFAULT_HOUR = 9;
const DEFAULT_MINUTE = 0;
const DEFAULT_TIMEZONE = "UTC";
const MINUTE_INTERVAL = 5;

type ZonedDateParts = {
    year: number;
    month: number;
    day: number;
    hour: number;
    minute: number;
};

type ErrorLike = {
    code?: unknown;
    details?: unknown;
    message?: unknown;
    stack?: unknown;
};

export const scheduleTodoReminder = onSchedule({
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
                    ...serializeError(error)
                });
                return;
            }

            for (const userDoc of usersSnapshot.docs) {
                const userId = userDoc.id;
                let settingsDoc: FirebaseFirestore.DocumentSnapshot<FirebaseFirestore.DocumentData>;
                try {
                    settingsDoc = await admin.firestore().doc(`users/${userId}/userData/settings`).get();
                } catch (error) {
                    logger.error("settings 조회 실패", {
                        userId,
                        at: "users/{uid}/userData/settings",
                        ...serializeError(error)
                    });
                    continue;
                }
                const settings = settingsDoc.data();
                if (!settings || settings.allowPushNotification !== true) {
                    continue;
                }
                
                const hour = Number.isInteger(settings.pushNotificationHour) ?
                    settings.pushNotificationHour :
                    DEFAULT_HOUR;
                const minute = normalizeMinute(settings.pushNotificationMinute);
                const timeZone = resolveTimeZone(settings);

                const localNow = getZonedParts(now, timeZone);
                if (!isWithinNotificationWindow(localNow, hour, minute)) {
                    continue;
                }

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

                const dueDateKey = formatDateKey(startUTC, timeZone);
                let todosSnapshot: FirebaseFirestore.QuerySnapshot<FirebaseFirestore.DocumentData>;
                try {
                    todosSnapshot = await admin.firestore()
                        .collection(`users/${userId}/todoLists`)
                        .where("isCompleted", "==", false)
                        .where("dueDate", ">=", admin.firestore.Timestamp.fromDate(startUTC))
                        .where("dueDate", "<", admin.firestore.Timestamp.fromDate(endUTC))
                        .get();
                } catch (error) {
                    logger.error("todoLists 조회 실패", {
                        userId,
                        at: "todoLists.where(isCompleted==false).where(dueDate>=start).where(dueDate<end)",
                        startUTC: startUTC.toISOString(),
                        endUTC: endUTC.toISOString(),
                        dueDateKey,
                        ...serializeError(error)
                    });
                    continue;
                }

                for (const todoDoc of todosSnapshot.docs) {
                    const todoData = todoDoc.data();
                    const todoTitle = typeof todoData.title === "string" && todoData.title.trim() ?
                        todoData.title :
                        "제목 없음";
                    const todoKind = typeof todoData.kind === "string" && todoData.kind.trim() ?
                        todoData.kind :
                        "etc";

                    const notificationTaskRef = admin.firestore().collection("notificationTasks").doc();
                    const notificationTaskData = {
                        userId,
                        todoId: todoDoc.id,
                        todoKind,
                        dueDateKey,
                        title: "DevLog",
                        body: `'${todoTitle}'의 마감일이 내일입니다.`,
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    };

                    try {
                        await notificationTaskRef.set(notificationTaskData);
                        await queue.enqueue({ taskId: notificationTaskRef.id });
                    } catch (error) {
                        try {
                            await notificationTaskRef.delete();
                        } catch (cleanupError) {
                            logger.warn("notificationTasks 정리 실패", {
                                userId,
                                todoId: todoDoc.id,
                                taskId: notificationTaskRef.id,
                                ...serializeError(cleanupError)
                            });
                        }
                        logger.error("Cloud Tasks enqueue 실패", {
                            userId,
                            todoId: todoDoc.id,
                            dueDateKey,
                            taskId: notificationTaskRef.id,
                            ...serializeError(error)
                        });
                    }
                }
            }

        } catch (error) {
            logger.error("알림 스케줄 배치 실행 중 오류 발생", serializeError(error));
        }
    }
);

function serializeError(error: unknown): Record<string, unknown> {
    const err = error as ErrorLike;
    return {
        code: err?.code ?? null,
        details: err?.details ?? null,
        message: err?.message ?? String(error),
        stack: err?.stack ?? null
    };
}

function getZonedParts(date: Date, timeZone: string): ZonedDateParts {
    const parts = new Intl.DateTimeFormat("en-US", {
        timeZone,
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit",
        hour12: false
    }).formatToParts(date);

    const byType = (type: string): number => {
        const found = parts.find((part) => part.type === type)?.value;
        return Number(found);
    };

    return {
        year: byType("year"),
        month: byType("month"),
        day: byType("day"),
        hour: byType("hour"),
        minute: byType("minute")
    };
}

function formatDateKey(date: Date, timeZone: string): string {
    const parts = new Intl.DateTimeFormat("en-CA", {
        timeZone,
        year: "numeric",
        month: "2-digit",
        day: "2-digit"
    }).formatToParts(date);

    const year = parts.find((part) => part.type === "year")?.value ?? "1970";
    const month = parts.find((part) => part.type === "month")?.value ?? "01";
    const day = parts.find((part) => part.type === "day")?.value ?? "01";
    return `${year}-${month}-${day}`;
}

function parseShortOffsetToMinutes(shortOffset: string): number {
    if (shortOffset === "GMT" || shortOffset === "UTC") return 0;
    const match = shortOffset.match(/^GMT([+-])(\d{1,2})(?::(\d{2}))?$/);
    if (!match) return 0;

    const sign = match[1] === "-" ? -1 : 1;
    const hour = Number(match[2]);
    const minute = Number(match[3] ?? "0");
    return sign * (hour * 60 + minute);
}

function getOffsetMinutesAt(utcDate: Date, timeZone: string): number {
    const parts = new Intl.DateTimeFormat("en-US", {
        timeZone,
        timeZoneName: "shortOffset"
    }).formatToParts(utcDate);

    const offset = parts.find((part) => part.type === "timeZoneName")?.value ?? "GMT";
    return parseShortOffsetToMinutes(offset);
}

function zonedDateTimeToUTC(
    year: number,
    month: number,
    day: number,
    hour: number,
    minute: number,
    timeZone: string
): Date {
    const localAsUTC = Date.UTC(year, month - 1, day, hour, minute, 0, 0);
    let utcMs = localAsUTC;

    // DST 경계 시 오프셋이 바뀔 수 있어 2회 보정
    for (let i = 0; i < 2; i += 1) {
        const offsetMinutes = getOffsetMinutesAt(new Date(utcMs), timeZone);
        utcMs = localAsUTC - offsetMinutes * 60 * 1000;
    }

    return new Date(utcMs);
}

function addDays(year: number, month: number, day: number, value: number): {
    year: number;
    month: number;
    day: number;
} {
    const utcDate = new Date(Date.UTC(year, month - 1, day, 0, 0, 0, 0));
    utcDate.setUTCDate(utcDate.getUTCDate() + value);
    return {
        year: utcDate.getUTCFullYear(),
        month: utcDate.getUTCMonth() + 1,
        day: utcDate.getUTCDate()
    };
}

function normalizeMinute(value: unknown): number {
    if (!Number.isInteger(value)) return DEFAULT_MINUTE;
    const minute = Number(value);
    if (minute < 0 || minute > 59) return DEFAULT_MINUTE;
    return minute - (minute % MINUTE_INTERVAL);
}

function isWithinNotificationWindow(
    localNow: ZonedDateParts,
    configuredHour: number,
    configuredMinute: number
): boolean {
    if (localNow.hour !== configuredHour) return false;
    const windowStart = configuredMinute;
    const windowEnd = Math.min(configuredMinute + MINUTE_INTERVAL, 60);
    return localNow.minute >= windowStart && localNow.minute < windowEnd;
}

function resolveTimeZone(settings: FirebaseFirestore.DocumentData | undefined): string {
    const candidate = settings?.timeZone ?? settings?.timezone ?? settings?.region;
    if (typeof candidate !== "string" || !candidate.trim()) return DEFAULT_TIMEZONE;
    try {
        new Intl.DateTimeFormat("en-US", { timeZone: candidate }).format(new Date());
        return candidate;
    } catch {
        return DEFAULT_TIMEZONE;
    }
}
