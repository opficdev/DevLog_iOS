import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onTaskDispatched } from "firebase-functions/v2/tasks";
import { getFunctions } from "firebase-admin/functions";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { toError } from "../common/error";
import { FirestorePath } from "../common/firestorePath";

const LOCATION = "asia-northeast3";
const DELETE_DELAY_SECONDS = 5;

type WebPageDeletionPayload = {
    userId: string;
    urlString: string;
};

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
                // deletingAt: 삭제 요청은 되었지만, 5초 유예 후 최종 soft delete 되기 전 상태를 의미한다.
                deletingAt: admin.firestore.FieldValue.serverTimestamp(),
                isDeleted: false
            }, { merge: true });

            const queue = getFunctions().taskQueue(
                `locations/${LOCATION}/functions/completeWebPageDeletion`
            );
            await queue.enqueue(
                { userId, urlString },
                { scheduleDelaySeconds: DELETE_DELAY_SECONDS }
            );
        } catch (error) {
            const currentWebPageSnapshot = await webPageRef.get();
            if (currentWebPageSnapshot.exists && currentWebPageSnapshot.data()?.isDeleted !== true) {
                await webPageRef.update({
                    deletingAt: admin.firestore.FieldValue.delete()
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
            if (currentWebPageSnapshot.exists && currentWebPageSnapshot.data()?.isDeleted !== true) {
                await webPageRef.update({
                    deletingAt: admin.firestore.FieldValue.delete(),
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

export const completeWebPageDeletion = onTaskDispatched({
        maxInstances: 1,
        region: LOCATION,
        retryConfig: { maxAttempts: 3, minBackoffSeconds: 5 },
        rateLimits: { maxDispatchesPerSecond: 200 },
    },
    async (request) => {
        const payload = parseDeletionPayload(request.data);
        if (!payload) {
            logger.warn("유효하지 않은 웹페이지 삭제 payload", request.data);
            return;
        }

        const { userId, urlString } = payload;
        const webPageSnapshot = await admin.firestore()
            .collection(FirestorePath.webPages(userId))
            .where("url", "==", urlString)
            .limit(1)
            .get();
        if (webPageSnapshot.empty) {
            return;
        }

        const webPageRef = webPageSnapshot.docs[0].ref;

        try {
            const currentWebPageSnapshot = await webPageRef.get();
            const deletingAt = currentWebPageSnapshot.data()?.deletingAt;
            const isDeleted = currentWebPageSnapshot.data()?.isDeleted === true;

            if (!currentWebPageSnapshot.exists || !deletingAt || isDeleted) {
                return;
            }

            await webPageRef.set({
                deletingAt: admin.firestore.FieldValue.delete(),
                isDeleted: true
            }, { merge: true });
        } catch (error) {
            logger.error("웹페이지 최종 soft delete 실패", toError(error), {
                userId,
                urlString
            });
            throw error;
        }
    }
);

function parseDeletionPayload(data: unknown): WebPageDeletionPayload | null {
    const userId = typeof (data as WebPageDeletionPayload | undefined)?.userId === "string" ?
        (data as WebPageDeletionPayload).userId.trim() :
        "";
    const urlString = typeof (data as WebPageDeletionPayload | undefined)?.urlString === "string" ?
        (data as WebPageDeletionPayload).urlString.trim() :
        "";

    if (!userId || !urlString) {
        return null;
    }

    return {
        userId,
        urlString
    };
}
