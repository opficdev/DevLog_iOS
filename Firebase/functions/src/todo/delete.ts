import { onDocumentDeleted, onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const LOCATION = "asia-northeast3";
const DELETE_BATCH_SIZE = 200;

export const deleteTodoNotificationReceipts = onDocumentDeleted({
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

export const deleteCompletedTodoReceipts = onDocumentUpdated({
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

        const dueDate = extractDate(afterData.dueDate);
        if (!dueDate || dueDate.getTime() >= Date.now()) { return; }

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

function extractDate(value: unknown): Date | null {
    if (value instanceof admin.firestore.Timestamp) {
        return value.toDate();
    }

    if (value instanceof Date) {
        return value;
    }

    return null;
}
