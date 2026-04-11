import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { toError } from "../common/error";
import { FirestorePath } from "../common/firestorePath";

const LOCATION = "asia-northeast3";

export const requestWebPageDeletion = onCall({
        cors: true,
        maxInstances: 3,
        region: LOCATION,
    },
    async (request) => {
        const userId = request.auth?.uid;
        const urlString = typeof request.data?.urlString === "string" ?
            request.data.urlString.trim() :
            "";

        if (!userId) {
            throw new HttpsError("unauthenticated", "인증된 사용자가 아닙니다.");
        }

        if (!urlString) {
            throw new HttpsError("invalid-argument", "urlString이 필요합니다.");
        }

        const webPageSnapshot = await admin.firestore()
            .collection(FirestorePath.webPages(userId))
            .where("url", "==", urlString)
            .limit(1)
            .get();

        if (webPageSnapshot.empty || webPageSnapshot.docs[0].data()?.isDeleted === true) {
            throw new HttpsError("not-found", "WebPage를 찾을 수 없습니다.");
        }

        const webPageRef = webPageSnapshot.docs[0].ref;

        try {
            await webPageRef.set({
                deletingAt: FieldValue.delete(),
                isDeleted: true
            }, { merge: true });
        } catch (error) {
            try {
                const currentWebPageSnapshot = await webPageRef.get();
                if (currentWebPageSnapshot.exists && currentWebPageSnapshot.data()?.isDeleted === true) {
                    await webPageRef.update({
                        deletingAt: FieldValue.delete(),
                        isDeleted: false
                    });
                }
            } catch (cleanupError) {
                logger.error("웹페이지 삭제 요청 cleanup 실패", toError(cleanupError), {
                    userId,
                    urlString
                });
            }

            logger.error("웹페이지 삭제 요청 실패", toError(error), {
                userId,
                urlString
            });
            throw new HttpsError("internal", "웹페이지 삭제 요청에 실패했습니다.");
        }

        return { success: true };
    }
);

export const undoWebPageDeletion = onCall({
        cors: true,
        maxInstances: 3,
        region: LOCATION,
    },
    async (request) => {
        const userId = request.auth?.uid;
        const urlString = typeof request.data?.urlString === "string" ?
            request.data.urlString.trim() :
            "";

        if (!userId) {
            throw new HttpsError("unauthenticated", "인증된 사용자가 아닙니다.");
        }

        if (!urlString) {
            throw new HttpsError("invalid-argument", "urlString이 필요합니다.");
        }

        const webPageSnapshot = await admin.firestore()
            .collection(FirestorePath.webPages(userId))
            .where("url", "==", urlString)
            .limit(1)
            .get();
        if (webPageSnapshot.empty) {
            return { success: true };
        }

        const webPageRef = webPageSnapshot.docs[0].ref;

        try {
            const currentWebPageSnapshot = await webPageRef.get();
            if (currentWebPageSnapshot.exists && currentWebPageSnapshot.data()?.isDeleted === true) {
                await webPageRef.update({
                    deletingAt: FieldValue.delete(),
                    isDeleted: false
                });
            }
        } catch (error) {
            logger.error("웹페이지 삭제 취소 실패", toError(error), {
                userId,
                urlString
            });
            throw new HttpsError("internal", "웹페이지 삭제 취소에 실패했습니다.");
        }

        return { success: true };
    }
);
