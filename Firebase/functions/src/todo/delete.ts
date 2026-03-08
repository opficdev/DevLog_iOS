import { onDocumentDeleted, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const LOCATION = "asia-northeast3";
const DELETE_BATCH_SIZE = 200;
const CLEANUP_QUERY_BATCH_SIZE = 100;

export const removeTodoNotificationDocuments = onDocumentDeleted({
        document: "users/{userId}/todoLists/{todoId}",
        region: LOCATION
    },
    async (event) => {
        const userId = event.params.userId;
        const todoId = event.params.todoId;

        try {
            await deleteByTodoId(userId, "notificationReceipts", todoId);
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

export const removeCompletedTodoReceipts = onDocumentUpdated({
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
            await deleteByTodoId(userId, "notificationReceipts", todoId);
        } catch (error) {
            logger.error("완료된 todo의 notificationReceipts 정리 실패", {
                userId,
                todoId,
                error
            });
        }
    }
);

export const removeExpiredCompletedTodoReceipts = onSchedule({
        region: LOCATION,
        schedule: "0 * * * *",
        timeZone: "UTC"
    },
    async () => {
        try {
            let lastDoc: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | undefined;

            while (true) {
                let query = admin.firestore()
                    .collectionGroup("todoLists")
                    .where("dueDate", "<", admin.firestore.Timestamp.now())
                    .orderBy("dueDate")
                    .limit(CLEANUP_QUERY_BATCH_SIZE);

                if (lastDoc) {
                    query = query.startAfter(lastDoc);
                }

                const snapshot = await query.get();
                if (snapshot.empty) { return; }

                for (const todoDoc of snapshot.docs) {
                    const todoData = todoDoc.data();
                    if (todoData.isCompleted !== true) { continue; }

                    const userId = todoDoc.ref.parent.parent?.id;
                    if (!userId) { continue; }

                    await deleteByTodoId(userId, "notificationReceipts", todoDoc.id);
                }

                if (snapshot.size < CLEANUP_QUERY_BATCH_SIZE) { return; }
                lastDoc = snapshot.docs[snapshot.docs.length - 1];
            }
        } catch (error) {
            logger.error("지난 마감일의 완료된 todo receipt 정리 실패", { error });
        }
    }
);

async function deleteByTodoId(
    userId: string,
    collectionName: "notificationReceipts" | "notifications",
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
