import * as admin from "firebase-admin";
import * as dotenv from "dotenv";
import * as path from "path";

// Apple 인증 관련 함수 가져오기
import {
    requestAppleCustomToken,
    requestAppleRefreshToken,
    refreshAppleAccessToken,
    revokeAppleAccessToken
} from "./auth/apple";

// GitHub 인증 관련 함수 가져오기
import {
    requestGithubTokens,
    revokeGithubAccessToken
} from "./auth/github";

// import {

// } from "./auth/google";

import {
    cleanupDeletedUserFirestoreData
} from "./user/delete";

import {
    sendPushNotification
} from "./fcm/notification";

import {
    scheduleTodoReminder
} from "./fcm/schedule";

import {
    removeTodoNotificationDocuments,
    removeCompletedTodoReceipts,
    removeStaleTodoReceipts
} from "./todo/remove";

import {
    requestTodoDeletion,
    undoTodoDeletion,
    completeTodoDeletion
} from "./todo/deletion";

import {
    requestPushNotificationDeletion,
    undoPushNotificationDeletion,
    completePushNotificationDeletion
} from "./notification/deletion";

import {
    requestWebPageDeletion,
    undoWebPageDeletion,
    completeWebPageDeletion
} from "./webPage/deletion";


// .env 파일 로드
dotenv.config({
    path: path.resolve(__dirname, "../.env"),
    override: true
});

// Firebase 앱 초기화
admin.initializeApp();

// Apple 인증 함수들 내보내기
export { 
    requestAppleCustomToken,
    requestAppleRefreshToken,
    refreshAppleAccessToken,
    revokeAppleAccessToken
};

// GitHub 인증 함수들 내보내기
export {
    requestGithubTokens,
    revokeGithubAccessToken
};

// Google 인증 함수들 (나중에 구현되면 추가)

export {
    cleanupDeletedUserFirestoreData
};

// FCM 관련 함수들 내보내기
export {
    sendPushNotification,
    scheduleTodoReminder
};

export {
    removeTodoNotificationDocuments,
    removeCompletedTodoReceipts,
    removeStaleTodoReceipts,
    requestTodoDeletion,
    undoTodoDeletion,
    completeTodoDeletion,
    requestPushNotificationDeletion,
    undoPushNotificationDeletion,
    completePushNotificationDeletion,
    requestWebPageDeletion,
    undoWebPageDeletion,
    completeWebPageDeletion
};
