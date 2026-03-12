import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

export const cleanupDeletedUserFirestoreData = functions
    .region("asia-northeast3")
    .auth
    .user()
    .onDelete(async (user) => {
        const uid = user.uid;

        try {
            const userDocRef = admin.firestore().doc(`users/${uid}`);
            await admin.firestore().recursiveDelete(userDocRef);
            logger.info("Deleted Firestore user data after Auth user deletion", { uid });
        } catch (error) {
            logger.error("Failed to delete Firestore user data after Auth user deletion", {
                uid,
                error
            });
            throw error;
        }
    }
);
