//
//  PushNotificationService.swift
//  DevLog
//
//  Created by opfic on 7/10/25.
//

import FirebaseAuth
import Combine
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
    func requestNotifications(
        _ notificationQuery: PushNotificationQuery,
        cursor: PushNotificationCursorDTO?
    ) async throws -> PushNotificationPageResponse {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        var firestoreQuery = makeQuery(uid: uid, query: notificationQuery)

        if let cursor {
            firestoreQuery = firestoreQuery.start(after: [
                Timestamp(date: cursor.receivedAt),
                cursor.documentID
            ])
        }

        let snapshot = try await firestoreQuery
            .limit(to: notificationQuery.pageSize)
            .getDocuments()

        let items = snapshot.documents.compactMap { makeResponse(from: $0) }

        let nextCursor: PushNotificationCursorDTO? = snapshot.documents.last.map { document in
            guard let receivedAt = document.data()[Key.receivedAt.rawValue] as? Timestamp else {
                return nil
            }

            return PushNotificationCursorDTO(
                receivedAt: receivedAt.dateValue(),
                documentID: document.documentID
            )
        } ?? nil

        return PushNotificationPageResponse(items: items, nextCursor: nextCursor)
    }

    func observeNotifications(
        _ query: PushNotificationQuery,
        limit: Int
    ) throws -> AnyPublisher<PushNotificationPageResponse, Error> {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        let subject = PassthroughSubject<PushNotificationPageResponse, Error>()
        let pageLimit = max(query.pageSize, limit)
        let listener = makeQuery(uid: uid, query: query)
            .limit(to: pageLimit)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    subject.send(completion: .failure(error))
                    return
                }

                guard let self, let snapshot else { return }

                let items = snapshot.documents.compactMap { self.makeResponse(from: $0) }
                let nextCursor = self.makeNextCursor(from: snapshot.documents.last)
                subject.send(
                    PushNotificationPageResponse(
                        items: items,
                        nextCursor: nextCursor
                    )
                )
            }

        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    /// 푸시 알림 기록 삭제
    func deleteNotification(_ notificationID: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw AuthError.notAuthenticated }

        let docRef = store.collection("users/\(uid)/notifications").document(notificationID)

        try await docRef.delete()
    }

    /// 푸시 알림 읽음/안읽음 토글
    func toggleNotificationRead(_ todoId: String) async throws {
        logger.info("Toggling notification read for todoId: \(todoId)")

        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        let collection = store.collection("users/\(uid)/notifications")
        let snapshot = try await collection.whereField("todoId", isEqualTo: todoId).getDocuments()

        guard let document = snapshot.documents.first else {
            logger.error("Notification not found for todoId: \(todoId)")
            throw FirestoreError.dataNotFound("notification")
        }

        guard let currentValue = document.data()["isRead"] as? Bool else {
            logger.error("isRead not found for notification: \(document.documentID)")
            throw FirestoreError.dataNotFound("isRead")
        }

        try await document.reference.updateData(["isRead": !currentValue])
        logger.info("Successfully toggled notification read")
    }
}

private extension PushNotificationService {
    func makeQuery(
        uid: String,
        query: PushNotificationQuery
    ) -> Query {
        var firestoreQuery: Query = store.collection("users/\(uid)/notifications")

        if let thresholdDate = query.timeFilter.thresholdDate {
            firestoreQuery = firestoreQuery.whereField(
                "receivedAt",
                isGreaterThanOrEqualTo: Timestamp(date: thresholdDate)
            )
        }

        if query.unreadOnly {
            firestoreQuery = firestoreQuery.whereField("isRead", isEqualTo: false)
        }

        let isDescending = query.sortOrder == .latest
        return firestoreQuery
            .order(by: "receivedAt", descending: isDescending)
            .order(by: FieldPath.documentID())
    }

    func makeNextCursor(from document: QueryDocumentSnapshot?) -> PushNotificationCursorDTO? {
        guard
            let document,
            let receivedAt = document.data()[Key.receivedAt.rawValue] as? Timestamp else {
            return nil
        }

        return PushNotificationCursorDTO(
            receivedAt: receivedAt.dateValue(),
            documentID: document.documentID
        )
    }

    func makeResponse(from snapshot: QueryDocumentSnapshot) -> PushNotificationResponse? {
        let data = snapshot.data()
        guard
            let title = data[Key.title.rawValue] as? String,
            let body = data[Key.body.rawValue] as? String,
            let receivedAt = data[Key.receivedAt.rawValue] as? Timestamp,
            let isRead = data[Key.isRead.rawValue] as? Bool,
            let todoId = data[Key.todoId.rawValue] as? String,
            let todoKind = data[Key.todoKind.rawValue] as? String else {
            return nil
        }

        return PushNotificationResponse(
            id: snapshot.documentID,
            title: title,
            body: body,
            receivedAt: receivedAt.dateValue(),
            isRead: isRead,
            todoId: todoId,
            todoKind: todoKind
        )
    }

    enum Key: String {
        case title
        case body
        case receivedAt
        case isRead
        case todoId
        case todoKind
    }
}
