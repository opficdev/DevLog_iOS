import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { normalizeError } from "../common/error";

const LOCATION = "asia-northeast3";
const BATCH_SIZE = 200;

export const syncTodoNotificationCategory = onDocumentUpdated({
        document: "users/{userId}/todoLists/{todoId}",
        region: LOCATION
    },
    async (event) => {
        const beforeData = event.data?.before.data();
        const afterData = event.data?.after.data();
        const userId = event.params.userId;
        const todoId = event.params.todoId;

        const beforeCategory = typeof beforeData?.category === "string" ? beforeData.category.trim() : "";
        const afterCategory = typeof afterData?.category === "string" ? afterData.category.trim() : "";

        if (!beforeCategory || !afterCategory || beforeCategory == afterCategory) {
            return;
        }

        try {
            await Promise.all([
                updateNotifications(userId, todoId, afterCategory),
                updateNotificationTasks(userId, todoId, afterCategory)
            ]);
        } catch (error) {
            logger.error("todo 카테고리 변경 후 알림 데이터 동기화 실패", {
                userId,
                todoId,
                beforeCategory,
                afterCategory,
                error: normalizeError(error)
            });
            throw error;
        }
    }
);

async function updateNotifications(
    userId: string,
    todoId: string,
    todoCategory: string
): Promise<void> {
    let lastDocument:
        FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | undefined;

    while (true) {
        let query = admin.firestore()
            .collection(`users/${userId}/notifications`)
            .where("todoId", "==", todoId)
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(BATCH_SIZE);

        if (lastDocument) {
            query = query.startAfter(lastDocument);
        }

        const snapshot = await query.get();
        if (snapshot.empty) { return; }

        const batch = admin.firestore().batch();
        snapshot.docs.forEach((document) => {
            batch.update(document.ref, { todoCategory });
        });
        await batch.commit();

        if (snapshot.size < BATCH_SIZE) { return; }
        lastDocument = snapshot.docs[snapshot.docs.length - 1];
    }
}

async function updateNotificationTasks(
    userId: string,
    todoId: string,
    todoCategory: string
): Promise<void> {
    let lastDocument:
        FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | undefined;

    while (true) {
        let query = admin.firestore()
            .collection("notificationTasks")
            .where("userId", "==", userId)
            .where("todoId", "==", todoId)
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(BATCH_SIZE);

        if (lastDocument) {
            query = query.startAfter(lastDocument);
        }

        const snapshot = await query.get();
        if (snapshot.empty) { return; }

        const batch = admin.firestore().batch();
        snapshot.docs.forEach((document) => {
            batch.update(document.ref, { todoCategory });
        });
        await batch.commit();

        if (snapshot.size < BATCH_SIZE) { return; }
        lastDocument = snapshot.docs[snapshot.docs.length - 1];
    }
}
