import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { toError } from "../common/error";

const LOCATION = "asia-northeast3";
const QUERY_BATCH_SIZE = 100;

// soft delete Todo 문서의 실제 삭제
export const cleanupSoftDeletedTodos = onSchedule({
        maxInstances: 1,
        region: LOCATION,
        schedule: "0 0 * * *",
        timeZone: "UTC"
    },
    async () => {
        try {
            let lastDocument:
                FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | undefined;

            while (true) {
                let query = admin.firestore()
                    .collectionGroup("todoLists")
                    .where("isDeleted", "==", true)
                    .orderBy(admin.firestore.FieldPath.documentId())
                    .limit(QUERY_BATCH_SIZE)
                if (lastDocument) {
                    query = query.startAfter(lastDocument);
                }

                const snapshot = await query.get();
                if (snapshot.empty) { return; }

                const batch = admin.firestore().batch();
                snapshot.docs.forEach((document) => {
                    batch.delete(document.ref);
                });
                await batch.commit();

                if (snapshot.size < QUERY_BATCH_SIZE) { return; }
                lastDocument = snapshot.docs[snapshot.docs.length - 1];
            }
        } catch (error) {
            logger.error(
                "soft delete Todo cleanup 실패",
                toError(error),
                {
                    collectionGroup: "todoLists",
                    filter: "isDeleted == true",
                    orderBy: "documentId",
                    queryBatchSize: QUERY_BATCH_SIZE
                }
            );
        }
    }
);
