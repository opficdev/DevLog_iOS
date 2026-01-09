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
    
    // 유저를 Firestore에 저장 및 업데이트
    func upsertUser(_ response: AuthenticationDataResponse) async throws {
        guard let user = Auth.auth().currentUser else { throw AuthError.notAuthenticated }
        let infoRef = store.document("users/\(user.uid)/userData/info")
        let tokensRef = store.document("users/\(user.uid)/userData/tokens")
        let settingsRef = store.document("users/\(user.uid)/userData/settings")
        
        // 사용자 기본 정보
        var userField: [String: Any] = [
            "statusMsg": "",
            "lastLogin": FieldValue.serverTimestamp()
        ]

        userField["currentProvider"] = response.providerID

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
        
        try await infoRef.setData(userField, merge: true)

        var settingField = ["fcmToken": response.fcmToken]

        // 깃헙 로그인 시 추가 정보 저장
        if response.providerID == "github.com", let accessToken = response.accessToken {
            settingField["githubAccessToken"] = accessToken
        }
        
        try await tokensRef.setData(settingField, merge: true)

        try await settingsRef.setData([
            "allowPushNotification": true,
            "theme": "automatic",
            "pushNotificationHour": 9,
            "pushNotificationMinute": 0], merge: true)
    }
    
    func fetchUserProfile() async throws -> UserProfileResponse {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        let infoRef = store.document("users/\(uid)/userData/info")

        let data = try await infoRef.getDocument().data()

        guard let provider = data?["currentProvider"] as? String,
              let name = data?[provider == "apple.com" ? "appleName" : "name"] as? String,
              let email = data?["email"] as? String,
              let statusMessage = data?["statusMsg"] as? String
        else {
            throw FirestoreError.dataNotFound
        }

        return UserProfileResponse(
            name: name,
            email: email,
            statusMessage: statusMessage,
            avatarURL: Auth.auth().currentUser?.photoURL
        )
    }
    
    func upsertStatusMessage(_ message: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthError.notAuthenticated
        }

        let infoRef = store.document("users/\(uid)/userData/info")

        try await infoRef.setData(["statusMsg": message], merge: true)
    }
    
    func fetchPushNotificationEnabled(_ userId: String) async throws -> Bool {
        let settingsRef = store.document("users/\(userId)/userData/settings")
        let doc = try await settingsRef.getDocument()
        
        if let allowPush = doc.data()?["allowPushNotification"] as? Bool { return allowPush }
        
        throw URLError(
            .badServerResponse,
            userInfo: [NSLocalizedDescriptionKey: "Push notification settings not found"]
        )
    }
    
    func fetchPushNotificationTime(_ userId: String) async throws -> DateComponents {
        let settingsRef = store.document("users/\(userId)/userData/settings")
        let doc = try await settingsRef.getDocument()
        
        guard let hour = doc.data()?["pushNotificationHour"] as? Int else {
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "Notification hour not found"])
        }
        
        guard let minute = doc.data()?["pushNotificationMinute"] as? Int else {
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "Notification minute not found"])
        }
        
        return DateComponents(hour: hour, minute: minute)
    }
    
    func updatePushNotificationEnabled(_ userId: String, enabled: Bool) async throws {
        let settingsRef = store.document("users/\(userId)/userData/settings")
        
        try await settingsRef.setData(["allowPushNotification": enabled], merge: true)
    }
    
    func updatePushNotificationTime(_ userId: String, time: Date) async throws {
        let settingRef = store.document("users/\(userId)/userData/settings")
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let hour = components.hour ?? 9
        let minute = components.minute ?? 0
        
        try await settingRef.setData([
            "pushNotificationHour": hour,
            "pushNotificationMinute": minute], merge: true)
    }
    
    func updateAppTheme(_ userId: String, theme: String) async throws {
        let settingsRef = store.document("users/\(userId)/userData/settings")
        
        try await settingsRef.setData(["theme": theme], merge: true)
    }
    
    func updateFCMToken(_ userId: String, fcmToken: String) async throws {
        let tokensRef = store.document("users/\(userId)/userData/tokens")
        
        try await tokensRef.setData(["fcmToken": fcmToken], merge: true)
    }
}
