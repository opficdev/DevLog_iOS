import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onTaskDispatched } from "firebase-functions/v2/tasks";
import { getFunctions } from "firebase-admin/functions";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { toError } from "../common/error";
import { FirestorePath } from "../common/firestorePath";

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
                const taskData = {
                    userId,
                    id
                };

                try {
                    await queue.enqueue(taskData);
                } catch (error) {
                    throw error;
                }
            }
        } catch (error) {
            logger.error("삭제된 사용자 카테고리 todo 정리 요청 실패", toError(error), {
                userId,
                removedIDs
            });
            throw error;
        }
    }
);

export const completeMoveRemovedCategoryTodosToEtc = onTaskDispatched({
        maxInstances: 2,
        region: LOCATION,
        retryConfig: { maxAttempts: 3, minBackoffSeconds: 5 },
        rateLimits: { maxDispatchesPerSecond: 2 },
    },
    async (request) => {
        const taskData = parseTaskPayload(request.data);
        if (!taskData) {
            logger.warn("유효하지 않은 카테고리 정리 payload", request.data);
            return;
        }
        const { userId, id } = taskData;

        try {
            await updateTodos(userId, id);
        } catch (error) {
            logger.error("삭제된 사용자 카테고리 todo 정리 실패", toError(error), {
                userId,
                id,
                payload: request.data
            });
            throw error;
        }
    }
);

function parseTaskPayload(data: unknown): TodoCategoryUpdateTaskData | null {
    const userId = typeof (data as TodoCategoryUpdateTaskData | undefined)?.userId === "string" ?
        (data as TodoCategoryUpdateTaskData).userId.trim() :
        "";
    const id = typeof (data as TodoCategoryUpdateTaskData | undefined)?.id === "string" ?
        (data as TodoCategoryUpdateTaskData).id.trim() :
        "";

    if (!userId || !id) {
        return null;
    }

    return {
        userId,
        id
    };
}

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
        .collection(FirestorePath.todos(userId))
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
