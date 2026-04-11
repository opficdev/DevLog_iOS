import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

type ZonedDateParts = {
    year: number;
    month: number;
    day: number;
    hour: number;
    minute: number;
};

// 지정한 타임존 기준 연월일시분 값 추출
export function getZonedParts(date: Date, timeZone: string): ZonedDateParts {
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

// GMT 오프셋 문자열의 분 단위 오프셋 값 변환
function parseShortOffsetToMinutes(shortOffset: string): number {
    if (shortOffset === "GMT" || shortOffset === "UTC") return 0;
    const match = shortOffset.match(/^GMT([+-])(\d{1,2})(?::(\d{2}))?$/);
    if (!match) return 0;

    const sign = match[1] === "-" ? -1 : 1;
    const hour = Number(match[2]);
    const minute = Number(match[3] ?? "0");
    return sign * (hour * 60 + minute);
}

// 특정 UTC 시점의 타임존 오프셋 분 단위 계산
function getOffsetMinutesAt(utcDate: Date, timeZone: string): number {
    const parts = new Intl.DateTimeFormat("en-US", {
        timeZone,
        timeZoneName: "shortOffset"
    }).formatToParts(utcDate);

    const offset = parts.find((part) => part.type === "timeZoneName")?.value ?? "GMT";
    return parseShortOffsetToMinutes(offset);
}

// 타임존 기준 로컬 날짜 시간의 UTC Date 변환
export function zonedDateTimeToUTC(
    year: number,
    month: number,
    day: number,
    hour: number,
    minute: number,
    timeZone: string
): Date {
    const localAsUTC = Date.UTC(year, month - 1, day, hour, minute, 0, 0);
    let utcMs = localAsUTC;

    // 첫 번째 계산은 로컬 시간을 그대로 UTC라고 가정한 임시값(localAsUTC) 기준 오프셋 조회
    // 하지만 실제로 필요한 오프셋은 해당 로컬 시각이 대응하는 UTC 시점의 값이므로 1차 결과만으로는
    // DST(일광 절약 시간) 경계 전후 중 어느 구간 오프셋을 참조했는지 확정할 수 없음
    // 따라서 1차 보정으로 얻은 UTC 기준 오프셋을 다시 조회해 한 번 더 계산하는 2회 보정 수행
    for (let i = 0; i < 2; i += 1) {
        const offsetMinutes = getOffsetMinutesAt(new Date(utcMs), timeZone);
        utcMs = localAsUTC - offsetMinutes * 60 * 1000;
    }

    return new Date(utcMs);
}

// 주어진 로컬 날짜에 대한 일 수 가산 결과 반환
export function addDays(year: number, month: number, day: number, value: number): {
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

// 타임존 기준 Date의 yyyy-MM-dd 형태 키 문자열 변환
export function formatDateKey(date: Date, timeZone: string): string {
    const parts = new Intl.DateTimeFormat("en-US", {
        timeZone,
        year: "numeric",
        month: "2-digit",
        day: "2-digit"
    }).formatToParts(date);

    const partMap = new Map(parts.map((part) => [part.type, part.value]));
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

// Firestore Timestamp 또는 Date 값을 일반 Date로 변환
export function toDate(value: unknown): Date | null {
    if (value instanceof admin.firestore.Timestamp) {
        return value.toDate();
    }

    if (value instanceof Date) {
        return value;
    }

    return null;
}
