//
//  UserService.swift
//  DevLog
//
//  Created by opfic on 6/4/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

final class UserService {
    private let store = Firestore.firestore()
    private let functions = Functions.functions(region: "asia-northeast3")
    private let logger = Logger(category: "UserService")
    
    // 유저를 Firestore에 저장 및 업데이트
    func upsertUser(_ response: AuthDataResponse) async throws {
        logger.info("Upserting user with provider: \(response.providerID)")
        
        guard let user = Auth.auth().currentUser else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        do {
            let userRef = store.document("users/\(user.uid)")
            let infoRef = store.document("users/\(user.uid)/userData/info")
            let tokensRef = store.document("users/\(user.uid)/userData/tokens")
            let settingsRef = store.document("users/\(user.uid)/userData/settings")

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

            let userDocument = try await userRef.getDocument()
            if !userDocument.exists {
                userField["statusMsg"] = ""
            }

            var settingField = ["fcmToken": response.fcmToken]

            // 깃헙 로그인 시 추가 정보 저장
            if response.providerID == "github.com", let accessToken = response.accessToken {
                settingField["githubAccessToken"] = accessToken
            }

            // Reference to capture ~ in concurrently-executing code; Swift 6 lang mode의 경고 해결
            let userFieldSnapshot = userField
            let settingFieldSnapshot = settingField
            // -----------------------------------------------------

            async let userUpdate: Void = userRef.setData(
                ["updatedAt": FieldValue.serverTimestamp()],
                merge: true
            )
            async let infoUpdate: Void = infoRef.setData(userFieldSnapshot, merge: true)
            async let tokensUpdate: Void = tokensRef.setData(settingFieldSnapshot, merge: true)

            let settingsDocument = try await settingsRef.getDocument()
            var settingsField: [String: Any] = [
                "timeZone": TimeZone.autoupdatingCurrent.identifier
            ]
            if !settingsDocument.exists {
                settingsField["allowPushNotification"] = true
                settingsField["pushNotificationHour"] = 9
                settingsField["pushNotificationMinute"] = 0
            }

            let settingsFieldSnapshot = settingsField
            async let settingsUpdate: Void = settingsRef.setData(settingsFieldSnapshot, merge: true)

            _ = try await (userUpdate, infoUpdate, tokensUpdate, settingsUpdate)
            
            logger.info("Successfully upserted user: \(user.uid)")
        } catch {
            logger.error("Failed to upsert user", error: error)
            throw error
        }
    }
    
    func fetchUserProfile() async throws -> UserProfileResponse {
        logger.info("Fetching user profile")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        do {
            let infoRef = store.document("users/\(uid)/userData/info")
            let data = try await infoRef.getDocument().data()

            guard let provider = data?["currentProvider"] as? String,
                  let name = data?[provider == "apple.com" ? "appleName" : "name"] as? String,
                  let email = data?["email"] as? String,
                  let statusMessage = data?["statusMsg"] as? String
            else {
                logger.error("User profile data not found")
                throw FirestoreError.dataNotFound("User Profile")
            }

            logger.info("Successfully fetched user profile for: \(email)")
            return UserProfileResponse(
                name: name,
                email: email,
                statusMessage: statusMessage,
                avatarURL: Auth.auth().currentUser?.photoURL
            )
        } catch {
            logger.error("Failed to fetch user profile", error: error)
            throw error
        }
    }
    
    func upsertStatusMessage(_ message: String) async throws {
        logger.info("Upserting status message")
        
        guard let uid = Auth.auth().currentUser?.uid else {
            logger.error("User not authenticated")
            throw AuthError.notAuthenticated
        }

        do {
            let infoRef = store.document("users/\(uid)/userData/info")
            try await infoRef.setData(["statusMsg": message], merge: true)
            logger.info("Successfully upserted status message")
        } catch {
            logger.error("Failed to upsert status message", error: error)
            throw error
        }
    }
    
    func updateFCMToken(_ userId: String, fcmToken: String) async throws {
        logger.info("Updating FCM token for user: \(userId)")
        
        do {
            let tokensRef = store.document("users/\(userId)/userData/tokens")
            try await tokensRef.setData(["fcmToken": fcmToken], merge: true)
            logger.info("Successfully updated FCM token")
        } catch {
            logger.error("Failed to update FCM token", error: error)
            throw error
        }
    }
}
