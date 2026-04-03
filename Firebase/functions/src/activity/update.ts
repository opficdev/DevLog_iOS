import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { formatDateKey, toDate } from "../common/date";
import { toError } from "../common/error";
import { FirestorePath } from "../common/firestorePath";

const LOCATION = "asia-northeast3";
const DEFAULT_TIME_ZONE = "UTC";

type ActivityKind = "created" | "completed" | "deleted";
type DailyCountField = "createdCount" | "completedCount" | "deletedCount";

// Firestore before/after 문서를 집계 비교에 필요한 값만 남긴 내부 스냅샷
type ActivitySnapshot = {
    exists: boolean;
    title: string;
    number: number | null;
    category: string;
    createdAt: Date | null;
    completedAt: Date | null;
    updatedAt: Date | null;
    isCompleted: boolean;
    isDeleted: boolean;
};

type ActivityEventPayload = {
    todoId: string;
    kind: ActivityKind;
    dayKey: string;
    occurredAt: FirebaseFirestore.Timestamp;
    todoTitle: string;
    todoNumber: number | null;
    todoCategory: string;
};

// Todo 변경을 activity 집계 문서와 activityEvents 문서로 동기화
export const syncTodoActivity = onDocumentWritten({
        document: "users/{userId}/todoLists/{todoId}",
        maxInstances: 1,
        region: LOCATION
    },
    async (event) => {
        const userId = event.params.userId;
        const todoId = event.params.todoId;
        const beforeSnapshot = makeActivitySnapshot(event.data?.before.data());
        const afterSnapshot = makeActivitySnapshot(event.data?.after.data());

        if (!afterSnapshot.exists) { return; }

        try {
            const timeZone = await fetchUserTimeZone(userId);
            const beforeCompletedDayKey = completedDayKey(beforeSnapshot, timeZone);
            const afterCompletedDayKey = completedDayKey(afterSnapshot, timeZone);
            const beforeDeletedDayKey = deletedDayKey(beforeSnapshot, timeZone);
            const afterDeletedDayKey = deletedDayKey(afterSnapshot, timeZone);
            const afterCreatedDayKey = createdDayKey(afterSnapshot, timeZone);
            const batch = admin.firestore().batch();

            // 최초 생성 시 생성 카운트만 증가
            if (!beforeSnapshot.exists && afterCreatedDayKey) {
                increaseDailyCount(batch, userId, afterCreatedDayKey, "createdCount", 1);
            }

            // 완료 상태 또는 완료일이 바뀌면 이전/현재 일자의 카운트를 각각 보정
            if (beforeCompletedDayKey !== afterCompletedDayKey) {
                if (beforeCompletedDayKey) {
                    increaseDailyCount(batch, userId, beforeCompletedDayKey, "completedCount", -1);
                }
                if (afterCompletedDayKey) {
                    increaseDailyCount(batch, userId, afterCompletedDayKey, "completedCount", 1);
                }
            }

            // 삭제 상태 또는 삭제일이 바뀌면 이전/현재 일자의 카운트를 각각 보정
            if (beforeDeletedDayKey !== afterDeletedDayKey) {
                if (beforeDeletedDayKey) {
                    increaseDailyCount(batch, userId, beforeDeletedDayKey, "deletedCount", -1);
                }
                if (afterDeletedDayKey) {
                    increaseDailyCount(batch, userId, afterDeletedDayKey, "deletedCount", 1);
                }
            }

            // 생성 이벤트는 todo가 존재하는 동안 유지하면서 제목/번호/카테고리 스냅샷을 갱신
            if (afterCreatedDayKey) {
                upsertActivityEvent(
                    batch,
                    userId,
                    todoId,
                    "created",
                    makeActivityEventPayload(
                        todoId,
                        "created",
                        afterCreatedDayKey,
                        afterSnapshot.createdAt,
                        afterSnapshot
                    )
                );
            }

            // 완료 상태일 때만 완료 이벤트 문서를 유지
            if (afterCompletedDayKey) {
                upsertActivityEvent(
                    batch,
                    userId,
                    todoId,
                    "completed",
                    makeActivityEventPayload(
                        todoId,
                        "completed",
                        afterCompletedDayKey,
                        afterSnapshot.completedAt,
                        afterSnapshot
                    )
                );
            } else if (beforeCompletedDayKey) {
                deleteActivityEvent(batch, userId, todoId, "completed");
            }

            // 삭제 상태일 때만 삭제 이벤트 문서를 유지
            if (afterDeletedDayKey) {
                upsertActivityEvent(
                    batch,
                    userId,
                    todoId,
                    "deleted",
                    makeActivityEventPayload(
                        todoId,
                        "deleted",
                        afterDeletedDayKey,
                        deletedOccurredAt(afterSnapshot),
                        afterSnapshot
                    )
                );
            } else if (beforeDeletedDayKey) {
                deleteActivityEvent(batch, userId, todoId, "deleted");
            }

            await batch.commit();
        } catch (error) {
            logger.error("todo activity 동기화 실패", toError(error), {
                userId,
                todoId
            });
            throw error;
        }
    }
);

// 원본 todo 문서를 null-safe한 비교용 스냅샷으로 정규화
function makeActivitySnapshot(data: FirebaseFirestore.DocumentData | undefined): ActivitySnapshot {
    return {
        exists: data !== undefined,
        title: typeof data?.title === "string" ? data.title : "",
        number: typeof data?.number === "number" ? data.number : null,
        category: typeof data?.category === "string" ? data.category : "",
        createdAt: toDate(data?.createdAt),
        completedAt: toDate(data?.completedAt),
        updatedAt: toDate(data?.updatedAt),
        isCompleted: data?.isCompleted === true,
        isDeleted: data?.isDeleted === true
    };
}

// 사용자 기준 날짜 키를 맞추기 위해 settings.timeZone을 조회
async function fetchUserTimeZone(userId: string): Promise<string> {
    const settingsSnapshot = await admin.firestore()
        .doc(FirestorePath.userData(userId, FirestorePath.UserDataDocument.settings))
        .get();
    const timeZone = typeof settingsSnapshot.data()?.timeZone === "string" ?
        settingsSnapshot.data()?.timeZone.trim() :
        "";

    return timeZone || DEFAULT_TIME_ZONE;
}

// 생성 이벤트는 createdAt 기준으로 집계
function createdDayKey(snapshot: ActivitySnapshot, timeZone: string): string | null {
    if (!snapshot.createdAt) {
        return null;
    }
    return formatDateKey(snapshot.createdAt, timeZone);
}

// 완료 이벤트는 현재 완료 상태일 때만 completedAt 기준으로 집계
function completedDayKey(snapshot: ActivitySnapshot, timeZone: string): string | null {
    if (!snapshot.isCompleted || !snapshot.completedAt) {
        return null;
    }
    return formatDateKey(snapshot.completedAt, timeZone);
}

// 삭제 이벤트는 soft delete가 기록된 시점(updatedAt 우선)을 기준으로 집계
function deletedDayKey(snapshot: ActivitySnapshot, timeZone: string): string | null {
    if (!snapshot.isDeleted) {
        return null;
    }
    const occurredAt = deletedOccurredAt(snapshot);
    if (!occurredAt) {
        return null;
    }
    return formatDateKey(occurredAt, timeZone);
}

// 삭제 발생 시각은 isDeleted=true로 갱신된 updatedAt을 우선 사용
function deletedOccurredAt(snapshot: ActivitySnapshot): Date | null {
    return snapshot.updatedAt ?? snapshot.createdAt;
}

// activity/{dayKey} 문서의 카운트를 증감
function increaseDailyCount(
    batch: FirebaseFirestore.WriteBatch,
    userId: string,
    dayKey: string,
    field: DailyCountField,
    value: number
): void {
    batch.set(
        admin.firestore().doc(FirestorePath.activityDaily(userId, dayKey)),
        {
            dayKey,
            createdCount: 0,
            completedCount: 0,
            deletedCount: 0,
            [field]: admin.firestore.FieldValue.increment(value)
        },
        { merge: true }
    );
}

// activityEvents/{kind}_{todoId} 문서를 생성 또는 갱신
function upsertActivityEvent(
    batch: FirebaseFirestore.WriteBatch,
    userId: string,
    todoId: string,
    kind: ActivityKind,
    payload: ActivityEventPayload
): void {
    batch.set(
        admin.firestore().doc(FirestorePath.activityEvent(userId, activityEventId(kind, todoId))),
        payload,
        { merge: true }
    );
}

// 더 이상 유효하지 않은 활동 이벤트 문서를 제거
function deleteActivityEvent(
    batch: FirebaseFirestore.WriteBatch,
    userId: string,
    todoId: string,
    kind: ActivityKind
): void {
    batch.delete(
        admin.firestore().doc(FirestorePath.activityEvent(userId, activityEventId(kind, todoId)))
    );
}

// 이벤트 문서 ID는 kind와 todoId 조합으로 고정
function activityEventId(kind: ActivityKind, todoId: string): string {
    return `${kind}_${todoId}`;
}

// 히트맵의 목록에서 바로 쓸 수 있도록 표시용 todo 스냅샷을 함께 저장
function makeActivityEventPayload(
    todoId: string,
    kind: ActivityKind,
    dayKey: string,
    occurredAt: Date | null,
    snapshot: ActivitySnapshot
): ActivityEventPayload {
    const safeOccurredAt = occurredAt ?? snapshot.updatedAt ?? snapshot.createdAt ?? new Date();

    return {
        todoId,
        kind,
        dayKey,
        occurredAt: admin.firestore.Timestamp.fromDate(safeOccurredAt),
        todoTitle: snapshot.title,
        todoNumber: snapshot.number,
        todoCategory: snapshot.category
    };
}
