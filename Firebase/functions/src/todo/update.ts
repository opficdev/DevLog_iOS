import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { toError } from "../common/error";
import { FirestorePath } from "../common/firestorePath";

const LOCATION = "asia-northeast3";
const BATCH_SIZE = 200;

// Todo 카테고리 변경 시 기존 알림 문서 카테고리 동기화
export const syncTodoNotificationCategory = onDocumentUpdated({
        maxInstances: 1,
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
            await updateNotifications(userId, todoId, afterCategory);
        } catch (error) {
            logger.error("todo 카테고리 변경 후 알림 데이터 동기화 실패", toError(error), {
                userId,
                todoId,
                beforeCategory,
                afterCategory
            });
            throw error;
        }
    }
);

// 변경된 카테고리 값의 해당 Todo 알림 문서 반영
async function updateNotifications(
    userId: string,
    todoId: string,
    todoCategory: string
): Promise<void> {
    await updateNotificationBatch(userId, todoId, todoCategory)
}

// 알림 문서의 배치 단위 순회 및 카테고리 값 갱신
async function updateNotificationBatch(
    userId: string,
    todoId: string,
    todoCategory: string,
    lastDocument?:
        FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>
): Promise<void> {
    let query = admin.firestore()
        .collection(FirestorePath.notifications(userId))
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

    await updateNotificationBatch(
        userId,
        todoId,
        todoCategory,
        snapshot.docs[snapshot.docs.length - 1]
    );
}
