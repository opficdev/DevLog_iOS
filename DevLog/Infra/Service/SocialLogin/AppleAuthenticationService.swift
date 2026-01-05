//
//  AppleAuthenticationService.swift
//  DevLog
//
//  Created by opfic on 6/4/25.
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import FirebaseMessaging
import Foundation

final class AppleAuthenticationService: AuthenticationService {
    private var appleSignInDelegate: AppleSignInDelegate?
    private let store = Firestore.firestore()
    private let functions = Functions.functions(region: "asia-northeast3")
    private let messaging = Messaging.messaging()
    private var user: User? { Auth.auth().currentUser }
    private let providerID = AuthProviderID.apple

    func signIn() async throws -> AuthenticationDataResponse {
        let response = try await authenticateWithAppleAsync()
        
        let nonce = response.nonce
        let credential = response.credential
        let authorizationCode = response.authorizationCode
        let idTokenString = response.idTokenString
                
        // Firebase Function을 통해 customToken 요청
        let customToken = try await requestAppleCustomToken(
            idToken: idTokenString,
            authorizationCode: authorizationCode
        )
        
        // customToken으로 Firebase 로그인
        let result = try await Auth.auth().signIn(withCustomToken: customToken)
        
        let changeRequest = result.user.createProfileChangeRequest()
        var displayName: String?

        // 최초 사용자 가입 시 사용자 이름 설정
        if let fullName = credential.fullName {
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .long
            let formattedName = formatter.string(from: fullName)
            if !formattedName.isEmpty {
                displayName = formattedName
            }
        }

        // 이미 가입된 사용자일 경우 Firestore에서 사용자 이름 가져오기
        if displayName == nil {
            let doc = try await store.document("users/\(result.user.uid)/userData/info").getDocument()
            displayName = doc.data()?["appleName"] as? String
        }

        // FirebaseAuth 사용자 프로필 업데이트
        changeRequest.displayName = displayName ?? ""
        changeRequest.photoURL = nil    //  Apple ID 프로필 사진 URL은 제공되지 않음
        try await changeRequest.commitChanges()
        
        // FirebaseAuth 계정에 Apple ID 연결
        if !result.user.providerData.contains(where: { $0.providerID == providerID.rawValue }) {
            let appleCredential = OAuthProvider.credential(
                providerID: providerID,
                idToken: idTokenString,
                rawNonce: nonce
            )
            try await result.user.link(with: appleCredential)
        }

        let fcmToken = try await messaging.token()

        return result.user.toData(providerID: .apple, fcmToken: fcmToken)
    }

    func signOut(_ uid: String) async throws {
        let infoRef = store.document("users/\(uid)/userData/tokens")
        let doc = try await infoRef.getDocument()

        if doc.exists {
            try await infoRef.updateData(["fcmToken": FieldValue.delete()])
        }

        try await messaging.deleteToken()

        try Auth.auth().signOut()
    }

    func deleteAuth(_ uid: String) async throws {
        let token = try await refreshAppleAccessToken()

        try await revokeAppleAccessToken(token: token)

        let deleteFunction = functions.httpsCallable("deleteUserFirestoreData")

        _ = try await deleteFunction.call(["uid": uid])

        try await signOut(uid)
        try await user?.delete()
    }

    func link(uid: String, email: String) async throws {
        let response = try await authenticateWithAppleAsync()

        let nonce = response.nonce
        let credential = response.credential
        let authorizationCode = response.authorizationCode
        let idTokenString = response.idTokenString

        let refreshToken = try await requestAppleRefreshToken(uid: uid, authorizationCode: authorizationCode)

        guard let appleEmail = credential.email else {
            try await revokeAppleAccessToken(token: refreshToken)
            throw EmailFetchError.emailNotFound
        }

        if appleEmail != email {
            try await revokeAppleAccessToken(token: refreshToken)
            throw EmailFetchError.emailMismatch
        }

        let appleCredential = OAuthProvider.credential(
            providerID: providerID,
            idToken: idTokenString,
            rawNonce: nonce
        )

        try await user?.link(with: appleCredential)
    }

    func unlink(_ uid: String) async throws {
        let accessToken = try await refreshAppleAccessToken()

        try await revokeAppleAccessToken(token: accessToken)

        let tokensRef = store.document("users/\(uid)/userData/tokens")

        let doc = try await tokensRef.getDocument()

        if doc.exists {
            try await tokensRef.updateData([
                "appleRefreshToken": FieldValue.delete()
            ])
        }

        _ = try await user?.unlink(fromProvider: providerID.rawValue)
    }

    // Apple 인증 메서드
    @MainActor
    func authenticateWithAppleAsync() async throws -> AppleAuthResponse {
        // 자체 nonce 생성 및 해시화
        let nonce = UUID().uuidString
        let hashedNonce = SHA256.hash(data: Data(nonce.utf8)).map { String(format: "%02x", $0) }.joined()
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]   //  사용자 정보 요청
        request.nonce = hashedNonce //  Apple API는 SHA256 해시값을 요구함
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        let authorization = try await withCheckedThrowingContinuation { continuation in
            self.appleSignInDelegate = AppleSignInDelegate(continuation: continuation)
            controller.delegate = self.appleSignInDelegate
            controller.presentationContextProvider = self.appleSignInDelegate
            controller.performRequests()
        }

        // Apple ID 인증 결과 처리
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIdToken = credential.identityToken,
              let authorizationCode = credential.authorizationCode,
              let idTokenString = String(data: appleIdToken, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        
        return AppleAuthResponse(
                nonce: nonce,
                credential: credential,
                authorizationCode: authorizationCode,
                idTokenString: idTokenString
        )
    }
    
    // Apple CustomToken 발급 메서드
    private func requestAppleCustomToken(idToken: String, authorizationCode: Data) async throws -> String {
        guard let authorizationCode = String(data: authorizationCode, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        
        let requestTokenFunction = functions.httpsCallable("requestAppleCustomToken")
        let result = try await requestTokenFunction.call([
            "idToken": idToken,
            "authorizationCode": authorizationCode
        ])
        
        if let data = result.data as? [String: Any], let customToken = data["customToken"] as? String {
            return customToken
        }
        throw URLError(.badServerResponse)
    }

    // Apple AceessToken 재발급 메서드
    private func refreshAppleAccessToken() async throws -> String {
        let refreshFunction = functions.httpsCallable("refreshAppleAccessToken")
        let result = try await refreshFunction.call()

        guard let data = result.data as? [String: Any],
              let accessToken = data["token"] as? String else {
            throw URLError(.cannotParseResponse)
        }

        return accessToken
    }

    // Apple RefreshToken 발급 메서드
    func requestAppleRefreshToken(uid: String, authorizationCode: Data) async throws -> String {
        guard let authorizationCode = String(data: authorizationCode, encoding: .utf8) else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let requestFuction = functions.httpsCallable("requestAppleRefreshToken")
        
        let params: [String: Any] = [
            "authorizationCode": authorizationCode,
            "uid": uid
        ]
        
        let result = try await requestFuction.call(params)
        
        if let data = result.data as? [String: Any], let accessToken = data["refreshToken"] as? String {
            return accessToken
        }
        throw URLError(.badServerResponse)
    }
    
    // Apple AccessToken 취소 메서드
    func revokeAppleAccessToken(token: String) async throws {
        let revokeFunction = functions.httpsCallable("revokeAppleAccessToken")
        
        _ = try await revokeFunction.call(["token": token])
    }
}
