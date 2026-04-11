import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { toError } from "../common/error";

const LOCATION = "asia-northeast3";
const CLEANUP_BATCH_SIZE = 200;

export const cleanupSoftDeletedWebPages = onSchedule({
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
                    .collectionGroup("webPages")
                    .where("isDeleted", "==", true)
                    .orderBy(admin.firestore.FieldPath.documentId())
                    .limit(CLEANUP_BATCH_SIZE)
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

                if (snapshot.size < CLEANUP_BATCH_SIZE) { return; }
                lastDocument = snapshot.docs[snapshot.docs.length - 1];
            }
        } catch (error) {
            logger.error("soft delete WebPage cleanup 실패", toError(error), {
                collectionGroup: "webPages",
                filter: "isDeleted == true",
                orderBy: "documentId",
                cleanupBatchSize: CLEANUP_BATCH_SIZE
            });
        }
    }
);
