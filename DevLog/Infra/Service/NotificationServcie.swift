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
