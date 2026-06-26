//
//  PushNotificationServiceImpl.swift
//  DevLogInfra
//
//  Created by opfic on 7/10/25.
//

import FirebaseAuth
import Combine
import FirebaseFirestore
import FirebaseFunctions
import DevLogCore
import DevLogData

final class PushNotificationServiceImpl: PushNotificationService {
    private enum CrashlyticsError {
        static let domain = "DevLogInfra.PushNotificationServiceImpl"

        enum Code: Int {
            case fetchPushNotificationEnabled = 1
            case fetchPushNotificationTime
            case updatePushNotificationSettings
            case requestNotifications
            case observeNotifications
            case observeUnreadPushCount
            case deleteNotification
            case undoDeleteNotification
            case toggleNotificationRead
        }
    }

    private enum FunctionName: String {
        case requestPushNotificationDeletion
        case undoPushNotificationDeletion
    }

    private let store = FirebaseConfiguration.firestore
    private let functions = FirebaseConfiguration.functions
    private let logger = Logger(category: "PushNotificationServiceImpl")

    /// 푸시 알림 On/Off 설정
    func fetchPushNotificationEnabled() async throws -> Bool {
        logger.info("Fetching push notification enabled status")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw DataLayerError.notAuthenticated
        }

        do {
            let settingsRef = store.document(FirestorePath.userData(uid, document: .settings))
            let doc = try await settingsRef.getDocument()

            if let allowPush = doc.data()?["allowPushNotification"] as? Bool {
                logger.info("Push notification enabled: \(allowPush)")
                return allowPush
            }

            logger.error("Push notification setting not found")
            throw FirestoreError.dataNotFound("allowPushNotification")
        } catch {
            logger.error("Failed to fetch push notification status", error: error)
            record(error, code: .fetchPushNotificationEnabled)
            throw error
        }
    }

    /// 푸시 알림 시간 설정
    func fetchPushNotificationTime() async throws -> DateComponents {
        logger.info("Fetching push notification time")

        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw DataLayerError.notAuthenticated
        }

        do {
            let settingsRef = store.document(FirestorePath.userData(uid, document: .settings))
            let doc = try await settingsRef.getDocument()

            guard let hour = doc.data()?["pushNotificationHour"] as? Int else {
                throw FirestoreError.dataNotFound("pushNotificationHour")
            }

            guard let minute = doc.data()?["pushNotificationMinute"] as? Int else {
                throw FirestoreError.dataNotFound("pushNotificationMinute")
            }

            return DateComponents(hour: hour, minute: minute)
        } catch {
            logger.error("Failed to fetch push notification time", error: error)
            record(error, code: .fetchPushNotificationTime)
            throw error
        }
    }

    /// 푸시 알림 설정 업데이트
    func updatePushNotificationSettings(isEnabled: Bool, components: DateComponents) async throws {
        logger.info("Updating push notification settings - enabled: \(isEnabled)")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw DataLayerError.notAuthenticated
        }

        do {
            let settingsRef = store.document(FirestorePath.userData(uid, document: .settings))

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
            record(error, code: .updatePushNotificationSettings)
            throw error
        }
    }

    /// 푸시 알림 기록 요청
    func requestNotifications(
        _ notificationQuery: PushNotificationQuery,
        cursor: PushNotificationCursorDTO?
    ) async throws -> PushNotificationPageResponse {
        do {
            guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

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
                guard let receivedAt = document.data()[PushNotificationFieldKey.receivedAt.rawValue] as? Timestamp
                else {
                    return nil
                }

                return PushNotificationCursorDTO(
                    receivedAt: receivedAt.dateValue(),
                    documentID: document.documentID
                )
            } ?? nil

            return PushNotificationPageResponse(items: items, nextCursor: nextCursor)
        } catch {
            logger.error("Failed to request notifications", error: error)
            record(error, code: .requestNotifications)
            throw error
        }
    }

    func observeNotifications(
        _ query: PushNotificationQuery,
        limit: Int
    ) throws -> AnyPublisher<PushNotificationPageResponse, Error> {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        let subject = PassthroughSubject<PushNotificationPageResponse, Error>()
        let pageLimit = max(query.pageSize, limit)
        let listener = makeQuery(uid: uid, query: query)
            .limit(to: pageLimit)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    Self.record(error, code: .observeNotifications)
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

    func observeUnreadPushCount() throws -> AnyPublisher<Int, Error> {
        guard let uid = Auth.auth().currentUser?.uid else { throw DataLayerError.notAuthenticated }

        let subject = PassthroughSubject<Int, Error>()
        let listener = store.collection(FirestorePath.notifications(uid))
            .whereField("isRead", isEqualTo: false)
            .whereField(PushNotificationFieldKey.isDeleted.rawValue, isEqualTo: false)
            .addSnapshotListener { snapshot, error in
                if let error {
                    Self.record(error, code: .observeUnreadPushCount)
                    subject.send(completion: .failure(error))
                    return
                }

                guard let snapshot else { return }
                let unreadPushCount = snapshot.documents.count
                subject.send(unreadPushCount)
            }

        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    /// 푸시 알림 기록 삭제
    func deleteNotification(_ notificationID: String) async throws {
        do {
            guard Auth.auth().currentUser?.uid != nil else { throw DataLayerError.notAuthenticated }

            let function = functions.httpsCallable(FunctionName.requestPushNotificationDeletion)
            _ = try await function.call(["notificationId": notificationID])
        } catch {
            logger.error("Failed to request notification deletion", error: error)
            record(error, code: .deleteNotification)
            throw error
        }
    }

    func undoDeleteNotification(_ notificationID: String) async throws {
        do {
            guard Auth.auth().currentUser?.uid != nil else { throw DataLayerError.notAuthenticated }

            let function = functions.httpsCallable(FunctionName.undoPushNotificationDeletion)
            _ = try await function.call(["notificationId": notificationID])
        } catch {
            logger.error("Failed to undo notification deletion", error: error)
            record(error, code: .undoDeleteNotification)
            throw error
        }
    }

    /// 푸시 알림 읽음/안읽음 토글
    func toggleNotificationRead(_ todoId: String) async throws {
        logger.info("Toggling notification read for todoId: \(todoId)")

        do {
            guard let uid = Auth.auth().currentUser?.uid else {
                logger.error("User not authenticated")
                throw DataLayerError.notAuthenticated
            }

            let collection = store.collection(FirestorePath.notifications(uid))
            let snapshot = try await collection
                .whereField("todoId", isEqualTo: todoId)
                .whereField(PushNotificationFieldKey.isDeleted.rawValue, isEqualTo: false)
                .getDocuments()

            guard let document = snapshot.documents.first else {
                logger.error("Notification not found for todoId: \(todoId)")
                throw FirestoreError.dataNotFound("notification")
            }

            try await toggleReadValue(for: document.reference)
            logger.info("Successfully toggled notification read")
        } catch {
            logger.error("Failed to toggle notification read", error: error)
            record(error, code: .toggleNotificationRead)
            throw error
        }
    }
}

private extension PushNotificationServiceImpl {
    private static func record(_ error: Error, code: CrashlyticsError.Code) {
        FirebaseCrashlyticsHelper.record(
            error,
            domain: "\(CrashlyticsError.domain).\(code)",
            code: code.rawValue
        )
    }

    private func record(_ error: Error, code: CrashlyticsError.Code) {
        Self.record(error, code: code)
    }

    func toggleReadValue(for notificationRef: DocumentReference) async throws {
        _ = try await store.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(notificationRef)
                guard let currentValue = snapshot.data()?["isRead"] as? Bool else {
                    throw FirestoreError.dataNotFound("isRead")
                }

                transaction.updateData(["isRead": !currentValue], forDocument: notificationRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            return nil
        }
    }

    func makeQuery(
        uid: String,
        query: PushNotificationQuery
    ) -> Query {
        var firestoreQuery: Query = store.collection(FirestorePath.notifications(uid))
            .whereField(PushNotificationFieldKey.isDeleted.rawValue, isEqualTo: false)

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
            let receivedAt = document.data()[PushNotificationFieldKey.receivedAt.rawValue] as? Timestamp else {
            return nil
        }

        return PushNotificationCursorDTO(
            receivedAt: receivedAt.dateValue(),
            documentID: document.documentID
        )
    }

    func makeResponse(from snapshot: QueryDocumentSnapshot) -> PushNotificationResponse? {
        let data = snapshot.data()
        if (data[PushNotificationFieldKey.isDeleted.rawValue] as? Bool) == true {
            return nil
        }
        guard
            let title = data[PushNotificationFieldKey.title.rawValue] as? String,
            let body = data[PushNotificationFieldKey.body.rawValue] as? String,
            let receivedAt = data[PushNotificationFieldKey.receivedAt.rawValue] as? Timestamp,
            let isRead = data[PushNotificationFieldKey.isRead.rawValue] as? Bool,
            let todoId = data[PushNotificationFieldKey.todoId.rawValue] as? String,
            let todoCategory = data[PushNotificationFieldKey.todoCategory.rawValue] as? String else {
            return nil
        }

        return PushNotificationResponse(
            id: snapshot.documentID,
            title: title,
            body: body,
            receivedAt: receivedAt.dateValue(),
            isRead: isRead,
            todoId: todoId,
            todoCategory: .raw(todoCategory)
        )
    }

    enum PushNotificationFieldKey: String {
        case title
        case body
        case receivedAt
        case isRead
        case todoId
        case todoCategory
        case isDeleted  // 삭제 요청으로 서버에서 soft deletion이 된 상태
    }
}
