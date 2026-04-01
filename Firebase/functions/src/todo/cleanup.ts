import { onDocumentDeleted, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const LOCATION = "asia-northeast3";
const DELETE_BATCH_SIZE = 200;
const QUERY_BATCH_SIZE = 100;

// Todo 삭제 시 연결된 알림 문서와 발송 기록 문서의 동시 제거
export const removeTodoNotificationDocuments = onDocumentDeleted({
        maxInstances: 1,
        document: "users/{userId}/todoLists/{todoId}",
        region: LOCATION
    },
    async (event) => {
        const userId = event.params.userId;
        const todoId = event.params.todoId;

        try {
            await deleteByTodoId(userId, "notificationDispatches", todoId);
            await deleteByTodoId(userId, "notifications", todoId);
        } catch (error) {
            logger.error("todo 삭제 후 notification 문서 정리 실패", {
                userId,
                todoId,
                error
            });
        }
    }
);

// 지난 마감일 Todo 완료 시 재발송 방지 기록 정리
export const removeCompletedTodoNotificationRecords = onDocumentUpdated({
        maxInstances: 1,
        document: "users/{userId}/todoLists/{todoId}",
        region: LOCATION
    },
    async (event) => {
        const beforeData = event.data?.before.data();
        const afterData = event.data?.after.data();
        const userId = event.params.userId;
        const todoId = event.params.todoId;

        if (!beforeData || !afterData) { return; }
        if (beforeData.isCompleted === true || afterData.isCompleted !== true) { return; }

        const dueDateValue = afterData.dueDate;
        let dueDate: Date | null = null;
        if (dueDateValue instanceof admin.firestore.Timestamp) {
            dueDate = dueDateValue.toDate();
        } else if (dueDateValue instanceof Date) {
            dueDate = dueDateValue;
        }
        
        if (!dueDate ||  Date.now() <= dueDate.getTime()) { return; }

        try {
            await deleteByTodoId(userId, "notificationDispatches", todoId);
        } catch (error) {
            logger.error("완료된 todo의 notification record 정리 실패", {
                userId,
                todoId,
                error
            });
        }
    }
);

// 사용되지 않는 알림 발송 기록의 주기적 정리
export const cleanupUnusedTodoNotificationRecords = onSchedule({
        maxInstances: 1,
        region: LOCATION,
        schedule: "0 * * * *",
        timeZone: "UTC"
    },
    async () => {
        try {
            let lastExpiredCompletedTodo:
                FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | undefined;

            while (true) {
                let query = admin.firestore()
                    .collectionGroup("todoLists")
                    .where("isCompleted", "==", true)
                    .where("dueDate", "<", admin.firestore.Timestamp.now())
                    .orderBy("dueDate")
                    .limit(QUERY_BATCH_SIZE);

                if (lastExpiredCompletedTodo) {
                    query = query.startAfter(lastExpiredCompletedTodo);
                }

                const snapshot = await query.get();
                if (snapshot.empty) { break; }

                for (const todoDoc of snapshot.docs) {
                    const userId = todoDoc.ref.parent.parent?.id;
                    if (!userId) { continue; }

                    await deleteByTodoId(userId, "notificationDispatches", todoDoc.id);
                }

                if (snapshot.size < QUERY_BATCH_SIZE) { break; }
                lastExpiredCompletedTodo = snapshot.docs[snapshot.docs.length - 1];
            }
        } catch (error) {
            logger.error("지난 마감일의 완료된 todo notification record 정리 실패", { error });
        }

        try {
            let lastTodoWithoutDueDate:
                FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | undefined;

            while (true) {
                let query = admin.firestore()
                    .collectionGroup("todoLists")
                    .where("dueDate", "==", null)
                    .orderBy(admin.firestore.FieldPath.documentId())
                    .limit(QUERY_BATCH_SIZE);

                if (lastTodoWithoutDueDate) {
                    query = query.startAfter(lastTodoWithoutDueDate);
                }

                const snapshot = await query.get();
                if (snapshot.empty) { break; }

                for (const todoDoc of snapshot.docs) {
                    const userId = todoDoc.ref.parent.parent?.id;
                    if (!userId) { continue; }

                    await deleteByTodoId(userId, "notificationDispatches", todoDoc.id);
                }

                if (snapshot.size < QUERY_BATCH_SIZE) { break; }
                lastTodoWithoutDueDate = snapshot.docs[snapshot.docs.length - 1];
            }
        } catch (error) {
            logger.error("마감일이 없는 todo notification record 정리 실패", { error });
        }
    }
);

// 특정 Todo 연결 문서의 배치 단위 전체 삭제
async function deleteByTodoId(
    userId: string,
    collectionName: "notificationDispatches" | "notifications",
    todoId: string
): Promise<void> {
    while (true) {
        const snapshot = await admin.firestore()
            .collection(`users/${userId}/${collectionName}`)
            .where("todoId", "==", todoId)
            .limit(DELETE_BATCH_SIZE)
            .get();

        if (snapshot.empty) { return; }

        const batch = admin.firestore().batch();
        snapshot.docs.forEach((document) => {
            batch.delete(document.ref);
        });
        await batch.commit();

        if (snapshot.size < DELETE_BATCH_SIZE) { return; }
    }
}
