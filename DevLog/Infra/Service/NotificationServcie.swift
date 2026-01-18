//
//  NotificationServcie.swift
//  DevLog
//
//  Created by opfic on 7/10/25.
//

import FirebaseAuth
import FirebaseFirestore

final class NotificationService {
    private let store = Firestore.firestore()

    /// 푸시 알림 On/Off 설정
    func fetchPushNotificationEnabled() async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        let settingsRef = store.document("users/\(uid)/userData/settings")
        let doc = try await settingsRef.getDocument()

        if let allowPush = doc.data()?["allowPushNotification"] as? Bool { return allowPush }

        throw FirestoreError.dataNotFound("allowPushNotification")
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

    /// 푸시 알림 On/Off 업데이트
    func updatePushNotificationEnabled(_ enabled: Bool) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        let settingsRef = store.document("users/\(uid)/userData/settings")

        try await settingsRef.setData(["allowPushNotification": enabled], merge: true)
    }

    /// 푸시 알림 시간 업데이트
    func updatePushNotificationTime(_ time: Date) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        let settingRef = store.document("users/\(uid)/userData/settings")

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let hour = components.hour ?? 9
        let minute = components.minute ?? 0

        try await settingRef.setData([
            "pushNotificationHour": hour,
            "pushNotificationMinute": minute], merge: true)
    }

    /// 푸시 알림 데이터 요청
    func requestNotification() async throws -> [PushNotification] {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        let collection = store.collection("users/\(uid)/notifications")

        let snapshot = try await collection.getDocuments()
        
        return snapshot.documents.compactMap { PushNotification(from: $0) }
    }

    /// 푸시 알림 데이터 삭제
    func deleteNotification(_ notificationID: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        let docRef = store.collection("users/\(uid)/notifications").document(notificationID)

        try await docRef.delete()
    }
}
