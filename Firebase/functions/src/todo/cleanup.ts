import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { toError } from "../common/error";

const LOCATION = "asia-northeast3";
const CLEANUP_BATCH_SIZE = 200;
const TOMBSTONE_GRACE_PERIOD_HOURS = 24;

// 삭제 후 유예 기간이 지난 todo를 표시용 최소 필드만 남는 축약 문서 형태로 압축
export const compactSoftDeletedTodos = onSchedule({
        maxInstances: 1,
        region: LOCATION,
        schedule: "0 9 * * *",
        timeZone: "Asia/Seoul"
    },
    async () => {
        const cutoff = new Date(Date.now() - (TOMBSTONE_GRACE_PERIOD_HOURS * 60 * 60 * 1000));

        try {
            let lastDocument:
                FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData> | undefined;

            while (true) {
                let query = admin.firestore()
                    .collectionGroup("todoLists")
                    .where("compactedAt", "==", null)
                    .where("deletedAt", "<=", admin.firestore.Timestamp.fromDate(cutoff))
                    .orderBy("deletedAt")
                    .orderBy(admin.firestore.FieldPath.documentId())
                    .limit(CLEANUP_BATCH_SIZE);
                if (lastDocument) {
                    query = query.startAfter(lastDocument);
                }

                const snapshot = await query.get();
                if (snapshot.empty) { return; }

                const batch = admin.firestore().batch();
                snapshot.docs.forEach((document) => {
                    batch.update(document.ref, {
                        compactedAt: admin.firestore.FieldValue.serverTimestamp(),
                        content: admin.firestore.FieldValue.delete(),
                        dueDate: admin.firestore.FieldValue.delete(),
                        isChecked: admin.firestore.FieldValue.delete(),
                        isCompleted: admin.firestore.FieldValue.delete(),
                        isDeleting: admin.firestore.FieldValue.delete(),
                        isPinned: admin.firestore.FieldValue.delete(),
                        isDeleted: admin.firestore.FieldValue.delete(),
                        tags: admin.firestore.FieldValue.delete()
                    });
                });
                await batch.commit();

                if (snapshot.size < CLEANUP_BATCH_SIZE) { return; }
                lastDocument = snapshot.docs[snapshot.docs.length - 1];
            }
        } catch (error) {
            logger.error(
                "soft deleted todo 축약 문서 압축 실패",
                toError(error),
                {
                    collectionGroup: "todoLists",
                    filter: `compactedAt == null && deletedAt <= now - ${TOMBSTONE_GRACE_PERIOD_HOURS}h`,
                    orderBy: ["deletedAt", "documentId"],
                    cleanupBatchSize: CLEANUP_BATCH_SIZE
                }
            );
        }
    }
);
