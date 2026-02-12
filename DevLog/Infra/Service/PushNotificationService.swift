//
//  PushNotificationService.swift
//  DevLog
//
//  Created by opfic on 7/10/25.
//

import FirebaseAuth
import FirebaseFirestore

final class PushNotificationService {
    private let store = Firestore.firestore()
    private let logger = Logger(category: "PushNotificationService")

    /// 푸시 알림 On/Off 설정
    func fetchPushNotificationEnabled() async throws -> Bool {
        logger.info("Fetching push notification enabled status")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        do {
            let settingsRef = store.document("users/\(uid)/userData/settings")
            let doc = try await settingsRef.getDocument()

            if let allowPush = doc.data()?["allowPushNotification"] as? Bool {
                logger.info("Push notification enabled: \(allowPush)")
                return allowPush
            }

            logger.error("Push notification setting not found")
            throw FirestoreError.dataNotFound("allowPushNotification")
        } catch {
            logger.error("Failed to fetch push notification status", error: error)
            throw error
        }
    }

    /// 푸시 알림 시간 설정
    func fetchPushNotificationTime() async throws -> DateComponents {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        let settingsRef = store.document("users/\(uid)/userData/settings")
        let doc = try await settingsRef.getDocument()

        guard let hour = doc.data()?["pushNotificationHour"] as? Int else {
            throw FirestoreError.dataNotFound("pushNotificationHour")
        }

        guard let minute = doc.data()?["pushNotificationMinute"] as? Int else {
            throw FirestoreError.dataNotFound("pushNotificationMinute")
        }

        return DateComponents(hour: hour, minute: minute)
    }

    /// 푸시 알림 설정 업데이트
    func updatePushNotificationSettings(isEnabled: Bool, components: DateComponents) async throws {
        logger.info("Updating push notification settings - enabled: \(isEnabled)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        do {
            let settingsRef = store.document("users/\(uid)/userData/settings")

            var dict: [String: Any] = ["allowPushNotification": isEnabled]

            if let hour = components.hour {
                dict["pushNotificationHour"] = hour
            }

            if let minute = components.minute {
                dict["pushNotificationMinute"] = minute
            }

            try await settingsRef.setData(dict, merge: true)
            logger.info("Successfully updated push notification settings")
        } catch {
            logger.error("Failed to update push notification settings", error: error)
            throw error
        }
    }

    /// 푸시 알림 기록 요청
    func requestNotifications() async throws -> [PushNotificationResponse] {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        let collection = store.collection("users/\(uid)/notifications")
        let snapshot = try await collection.getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: PushNotificationResponse.self)
        }
    }

    /// 푸시 알림 기록 삭제
    func deleteNotification(_ notificationID: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        let docRef = store.collection("users/\(uid)/notifications").document(notificationID)

        try await docRef.delete()
    }
}
