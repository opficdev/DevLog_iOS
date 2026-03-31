import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onTaskDispatched } from "firebase-functions/v2/tasks";
import { getFunctions } from "firebase-admin/functions";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { normalizeError } from "../common/error";

const LOCATION = "asia-northeast3";
const BATCH_SIZE = 200;
const ETC_CATEGORY = "etc";

type CategoryItem = {
    kind?: unknown;
    id?: unknown;
};

type TodoCategoryUpdateTaskData = {
    userId: string;
    id: string;
    createdAt?: FirebaseFirestore.Timestamp | Date | null;
};

export const requestMoveRemovedCategoryTodosToEtc = onDocumentUpdated({
        maxInstances: 1,
        document: "users/{userId}/userData/categories",
        region: LOCATION
    },
    async (event) => {
        const userId = event.params.userId;
        const beforeData = event.data?.before.data();
        const afterData = event.data?.after.data();

        if (!beforeData || !afterData) { return; }

        const beforeItems = Array.isArray(beforeData.items) ? beforeData.items as CategoryItem[] : [];
        const afterItems = Array.isArray(afterData.items) ? afterData.items as CategoryItem[] : [];
        const removedIDs = getRemovedIDs(beforeItems, afterItems);

        if (removedIDs.length === 0) { return; }

        try {
            const queue = getFunctions().taskQueue(
                `locations/${LOCATION}/functions/completeMoveRemovedCategoryTodosToEtc`
            );

            for (const id of removedIDs) {
                const taskRef = admin.firestore().collection("todoCategoryUpdateTasks").doc();
                const taskData = {
                    userId,
                    id,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                };

                try {
                    await taskRef.set(taskData);
                    await queue.enqueue({ taskId: taskRef.id });
                } catch (error) {
                    try {
                        await taskRef.delete();
                    } catch (cleanupError) {
                        logger.warn("todoCategoryUpdateTasks 정리 실패", {
                            userId,
                            id,
                            taskId: taskRef.id,
                            error: normalizeError(cleanupError)
                        });
                    }

                    throw error;
                }
            }
        } catch (error) {
            logger.error("삭제된 사용자 카테고리 todo 정리 요청 실패", {
                userId,
                removedIDs,
                error: normalizeError(error)
            });
            throw error;
        }
    }
);

export const completeMoveRemovedCategoryTodosToEtc = onTaskDispatched({
        maxInstances: 1,
        region: LOCATION,
        retryConfig: { maxAttempts: 3, minBackoffSeconds: 5 },
        rateLimits: { maxDispatchesPerSecond: 20 },
    },
    async (request) => {
        const taskId = typeof request.data?.taskId === "string" ? request.data.taskId.trim() : "";
        if (!taskId) {
            logger.warn("유효하지 않은 카테고리 정리 payload", request.data);
            return;
        }

        const taskRef = admin.firestore().collection("todoCategoryUpdateTasks").doc(taskId);
        const taskSnapshot = await taskRef.get();
        if (!taskSnapshot.exists) { return; }

        const taskData = taskSnapshot.data() as TodoCategoryUpdateTaskData | undefined;
        const userId = typeof taskData?.userId === "string" ? taskData.userId : "";
        const id = typeof taskData?.id === "string" ? taskData.id : "";

        if (!userId || !id) {
            logger.warn("todoCategoryUpdateTasks 문서 형식이 올바르지 않습니다.", { taskId });
            return;
        }

        try {
            await updateTodos(userId, id);
            await taskRef.delete();
        } catch (error) {
            logger.error("삭제된 사용자 카테고리 todo 정리 실패", {
                userId,
                id,
                taskId,
                error: normalizeError(error)
            });
            throw error;
        }
    }
);

function getRemovedIDs(
    beforeItems: CategoryItem[],
    afterItems: CategoryItem[]
): string[] {
    const beforeIDs = new Set(
        beforeItems.flatMap((item) => {
            if (item.kind !== "user") { return []; }
            return typeof item.id === "string" ? [item.id] : [];
        })
    );
    const afterIDs = new Set(
        afterItems.flatMap((item) => {
            if (item.kind !== "user") { return []; }
            return typeof item.id === "string" ? [item.id] : [];
        })
    );

    return Array.from(beforeIDs).filter((id) => !afterIDs.has(id));
}

async function updateTodos(
    userId: string,
    id: string
): Promise<void> {
    await updateTodoBatch(userId, id)
}

async function updateTodoBatch(
    userId: string,
    id: string,
    lastDocument?:
        FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>
): Promise<void> {
    let query = admin.firestore()
        .collection(`users/${userId}/todoLists`)
        .where("category", "==", id)
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(BATCH_SIZE);

    if (lastDocument) {
        query = query.startAfter(lastDocument);
    }

    const snapshot = await query.get();
    if (snapshot.empty) { return; }

    const batch = admin.firestore().batch();
    snapshot.docs.forEach((document) => {
        batch.update(document.ref, {
            category: ETC_CATEGORY
        });
    });
    await batch.commit();

    if (snapshot.size < BATCH_SIZE) { return; }

    await updateTodoBatch(
        userId,
        id,
        snapshot.docs[snapshot.docs.length - 1]
    );
}
