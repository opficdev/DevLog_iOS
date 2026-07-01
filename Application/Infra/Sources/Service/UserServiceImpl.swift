//
//  UserServiceImpl.swift
//  Infra
//
//  Created by opfic on 6/4/25.
//

import FirebaseAuth
import FirebaseFirestore
import Core
import Data

final class UserServiceImpl: UserService {
    private enum CrashlyticsError {
        static let domain = "DevLogInfra.UserServiceImpl"

        enum Code: Int {
            case upsertUser = 1
            case fetchUserProfile
            case upsertStatusMessage
            case updateFCMToken
            case updateUserTimeZone
        }
    }

    private let store = FirebaseConfiguration.firestore
    private let logger = Logger(category: "UserServiceImpl")
    
    // 유저를 Firestore에 저장 및 업데이트
    func upsertUser(_ response: AuthDataResponse) async throws {
        logger.info("Upserting user with provider: \(response.providerID)")
        
        guard let user = Auth.auth().currentUser else {
            logger.error("User not authenticated")
            throw DataLayerError.notAuthenticated
        }

        do {
            // 사용자 기본 정보
            var userField: [String: Any] = [
                "currentProvider": response.providerID
            ]

            // 공급자 이슈로 인한 nil 방지
            if let email = user.email {
                userField["email"] = email
            }
            
            if let displayName = user.displayName, displayName != "" {
                userField["name"] = displayName
            }

            // Apple은 최초 새 이름 설정 시에만 이름을 제공
            if response.providerID == "apple.com" &&
                user.displayName != nil && user.displayName != "" {
                userField["appleName"] = user.displayName
            }

            var tokenField: [String: Any] = [:]

            if let fcmToken = response.fcmToken {
                tokenField["fcmToken"] = fcmToken
            }

            // 깃헙 로그인 시 추가 정보 저장
            if response.providerID == "github.com", let accessToken = response.accessToken {
                tokenField["githubAccessToken"] = accessToken
            }

            try await upsertUserDocuments(
                uid: user.uid,
                userField: userField,
                tokenField: tokenField
            )
            
            logger.info("Successfully upserted user: \(user.uid)")
        } catch {
            logger.error("Failed to upsert user", error: error)
            record(error, code: .upsertUser)
            throw error
        }
    }
    
    func fetchUserProfile() async throws -> UserProfileResponse {
        logger.info("Fetching user profile")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw DataLayerError.notAuthenticated
        }

        do {
            let infoRef = store.document(FirestorePath.userData(uid, document: .info))
            let data = try await infoRef.getDocument().data()
            let createdAt = (data?["createdAt"] as? Timestamp)?.dateValue()
                ?? Auth.auth().currentUser?.metadata.creationDate

            guard let provider = data?["currentProvider"] as? String,
                  let name = data?[provider == "apple.com" ? "appleName" : "name"] as? String,
                  let email = data?["email"] as? String,
                  let statusMessage = data?["statusMsg"] as? String,
                  let createdAt
            else {
                logger.error("User profile data not found")
                throw FirestoreError.dataNotFound("User Profile")
            }

            logger.info("Successfully fetched user profile for: \(email)")
            return UserProfileResponse(
                name: name,
                email: email,
                statusMessage: statusMessage,
                avatarURL: Auth.auth().currentUser?.photoURL,
                createdAt: createdAt
            )
        } catch {
            logger.error("Failed to fetch user profile", error: error)
            record(error, code: .fetchUserProfile)
            throw error
        }
    }
    
    func upsertStatusMessage(_ message: String) async throws {
        logger.info("Upserting status message")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw DataLayerError.notAuthenticated
        }

        do {
            let infoRef = store.document(FirestorePath.userData(uid, document: .info))
            try await infoRef.setData(["statusMsg": message], merge: true)
            logger.info("Successfully upserted status message")
        } catch {
            logger.error("Failed to upsert status message", error: error)
            record(error, code: .upsertStatusMessage)
            throw error
        }
    }
    
    func updateFCMToken(_ fcmToken: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.info("Skipping FCM token update because no authenticated user exists")
            return
        }

        logger.info("Updating FCM token for user: \(uid)")

        do {
            let tokensRef = store.document(FirestorePath.userData(uid, document: .tokens))
            try await tokensRef.setData(["fcmToken": fcmToken], merge: true)
            logger.info("Successfully updated FCM token")
        } catch {
            logger.error("Failed to update FCM token", error: error)
            record(error, code: .updateFCMToken)
            throw error
        }
    }

    func updateUserTimeZone() async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.info("Skipping timeZone update because no authenticated user exists")
            return
        }

        logger.info("Updating timeZone for user: \(uid)")

        do {
            let settingsRef = store.document(FirestorePath.userData(uid, document: .settings))
            try await settingsRef.setData(
                ["timeZone": TimeZone.autoupdatingCurrent.identifier],
                merge: true
            )
            logger.info("Successfully updated timeZone")
        } catch {
            logger.error("Failed to update timeZone", error: error)
            record(error, code: .updateUserTimeZone)
            throw error
        }
    }
}

private extension UserServiceImpl {
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

    func upsertUserDocuments(
        uid: String,
        userField: [String: Any],
        tokenField: [String: Any]
    ) async throws {
        let userRef = store.document(FirestorePath.user(uid))
        let infoRef = store.document(FirestorePath.userData(uid, document: .info))
        let tokensRef = store.document(FirestorePath.userData(uid, document: .tokens))
        let settingsRef = store.document(FirestorePath.userData(uid, document: .settings))
        let todoCounterRef = store.document(FirestorePath.counter(uid, document: .todo))

        _ = try await store.runTransaction { transaction, errorPointer in
            let userDocument: DocumentSnapshot
            let settingsDocument: DocumentSnapshot

            do {
                userDocument = try transaction.getDocument(userRef)
                settingsDocument = try transaction.getDocument(settingsRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            var infoField = userField
            if !userDocument.exists {
                infoField["statusMsg"] = ""
                infoField["createdAt"] = FieldValue.serverTimestamp()
            }

            var settingsField: [String: Any] = [
                "timeZone": TimeZone.autoupdatingCurrent.identifier
            ]
            if !settingsDocument.exists {
                settingsField["allowPushNotification"] = true
                settingsField["pushNotificationHour"] = 9
                settingsField["pushNotificationMinute"] = 0
            }

            transaction.setData(
                ["updatedAt": FieldValue.serverTimestamp()],
                forDocument: userRef,
                merge: true
            )
            transaction.setData(infoField, forDocument: infoRef, merge: true)

            if !tokenField.isEmpty {
                transaction.setData(tokenField, forDocument: tokensRef, merge: true)
            }

            transaction.setData(settingsField, forDocument: settingsRef, merge: true)

            if !userDocument.exists {
                transaction.setData(
                    [
                        "nextNumber": 1,
                        "updatedAt": FieldValue.serverTimestamp()
                    ],
                    forDocument: todoCounterRef,
                    merge: true
                )
            }

            return nil
        }
    }
}
