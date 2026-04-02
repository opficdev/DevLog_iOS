import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { toError } from "../common/error";

const LOCATION = "asia-northeast3";
const CLEANUP_BATCH_SIZE = 200;

export const cleanupSoftDeletedNotifications = onSchedule({
        maxInstances: 1,
        region: LOCATION,
        schedule: "0 0 * * *",
        timeZone: "UTC"
    },
    async () => {
        try {
            while (true) {
                const snapshot = await admin.firestore()
                    .collectionGroup("notifications")
                    .where("isDeleted", "==", true)
                    .limit(CLEANUP_BATCH_SIZE)
                    .get();

                if (snapshot.empty) { return; }

                const batch = admin.firestore().batch();
                snapshot.docs.forEach((document) => {
                    batch.delete(document.ref);
                });
                await batch.commit();

                if (snapshot.size < CLEANUP_BATCH_SIZE) { return; }
            }
        } catch (error) {
            logger.error(
                "soft delete Notification cleanup 실패",
                toError(error),
                {
                    collectionGroup: "notifications",
                    filter: "isDeleted == true",
                    cleanupBatchSize: CLEANUP_BATCH_SIZE
                }
            );
        }
    }
);
