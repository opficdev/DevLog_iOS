//
//  AppleAuthenticationServiceImpl.swift
//  DevLogInfra
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
import DevLogCore
import DevLogData

final class AppleAuthenticationServiceImpl: AuthenticationService {
    private enum CrashlyticsError {
        static let domain = "DevLogInfra.AppleAuthenticationServiceImpl"

        enum Code: Int {
            case signIn = 1
            case signOut
            case deleteAuth
            case link
            case unlink
        }
    }

    private enum FunctionName: String {
        case requestAppleCustomToken
        case refreshAppleAccessToken
        case requestAppleRefreshToken
        case revokeAppleAccessToken
    }

    private var appleSignInDelegate: AppleSignInDelegate?
    private var appleSignInContinuation: CheckedContinuation<ASAuthorization, Error>?
    private let store = Firestore.firestore()
    private let functions = Functions.functions(region: "asia-northeast3")
    private let messaging = Messaging.messaging()
    private var user: User? { Auth.auth().currentUser }
    private let providerID = AuthProviderID.apple
    private let logger = Logger(category: "AppleAuthService")

    func signIn() async throws -> AuthDataResponse? {
        logger.info("Starting Apple sign in")
        
        do {
            let response = try await authenticateWithAppleAsync()
            
            let nonce = response.nonce
            let credential = response.credential
            let authorizationCode = response.authorizationCode
            let idTokenString = response.idTokenString
                    
            // Firebase Function을 통해 customToken 요청
            logger.debug("Requesting custom token from Firebase Function")
            let customToken = try await requestAppleCustomToken(
                idToken: idTokenString,
                authorizationCode: authorizationCode
            )
            
            // customToken으로 Firebase 로그인
            logger.debug("Signing in with custom token")
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
                let doc = try await store
                    .document(FirestorePath.userData(result.user.uid, document: .info))
                    .getDocument()
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

            logger.info("Successfully signed in with Apple")
            return result.user.makeResponse(providerID: .apple)
        } catch {
            if error.isSocialLoginCancelled { return nil }

            logger.error("Failed to sign in with Apple", error: error)
            record(error, code: .signIn)
            throw error
        }
    }

    func signOut(_ uid: String) async throws {
        do {
            let infoRef = store.document(FirestorePath.userData(uid, document: .tokens))
            try? await infoRef.updateData(["fcmToken": FieldValue.delete()])

            if messaging.fcmToken != nil {
                do {
                    try await messaging.deleteToken()
                } catch {
                    logger.error("Failed to delete FCM token while signing out with Apple", error: error)
                }
            }

            try Auth.auth().signOut()
        } catch {
            logger.error("Failed to sign out with Apple", error: error)
            record(error, code: .signOut)
            throw error
        }
    }

    func deleteAuth(_ uid: String) async throws {
        do {
            let token = try await refreshAppleAccessToken()

            try await revokeAppleAccessToken(token: token)
        } catch {
            logger.error("Failed to delete Apple auth", error: error)
            record(error, code: .deleteAuth)
            throw error
        }
    }

    func link(uid: String, email: String) async throws -> Bool {
        do {
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
            return true
        } catch {
            if error.isSocialLoginCancelled { return false }

            logger.error("Failed to link Apple account", error: error)
            record(error, code: .link)
            if error.isFirebaseCredentialAlreadyInUse {
                throw DataLayerError.linkCredentialAlreadyInUse
            }
            throw error
        }
    }

    func unlink(_ uid: String) async throws {
        do {
            logger.info("Starting Apple access token refresh for unlink. uid: \(uid)")
            let accessToken = try await refreshAppleAccessToken()

            logger.info("Starting Apple access token revocation for unlink. uid: \(uid)")
            try await revokeAppleAccessToken(token: accessToken)

            let tokensRef = store.document(FirestorePath.userData(uid, document: .tokens))

            logger.info("Starting Apple token document fetch for unlink. uid: \(uid)")
            let doc = try await tokensRef.getDocument()

            if doc.exists {
                logger.info("Starting Apple refresh token deletion from Firestore for unlink. uid: \(uid)")
                try await tokensRef.updateData([
                    "appleRefreshToken": FieldValue.delete()
                ])
            }

            logger.info("Starting Firebase Apple provider unlink. uid: \(uid)")
            _ = try await user?.unlink(fromProvider: providerID.rawValue)
        } catch {
            logger.error("Failed to unlink Apple account", error: error)
            record(error, code: .unlink)
            throw error
        }
    }

    // Apple 인증 메서드
    @MainActor
    func authenticateWithAppleAsync() async throws -> AppleAuthResponse {
        guard appleSignInDelegate == nil, appleSignInContinuation == nil else {
            throw SocialLoginError.authenticationAlreadyInProgress
        }

        // 자체 nonce 생성 및 해시화
        let nonce = UUID().uuidString
        let hashedNonce = SHA256.hash(data: Data(nonce.utf8)).map { String(format: "%02x", $0) }.joined()
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]   //  사용자 정보 요청
        request.nonce = hashedNonce //  Apple API는 SHA256 해시값을 요구함
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        let authorization = try await withCheckedThrowingContinuation { continuation in
            let delegate = AppleSignInDelegate { [weak self] result in
                self?.completeAppleSignIn(with: result)
            }
            self.appleSignInDelegate = delegate
            self.appleSignInContinuation = continuation
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

    @MainActor
    private func completeAppleSignIn(with result: Result<ASAuthorization, Error>) {
        guard let continuation = appleSignInContinuation else { return }

        appleSignInContinuation = nil
        appleSignInDelegate = nil

        switch result {
        case .success(let authorization):
            continuation.resume(returning: authorization)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
    
    // Apple CustomToken 발급 메서드
    private func requestAppleCustomToken(idToken: String, authorizationCode: Data) async throws -> String {
        guard let authorizationCode = String(data: authorizationCode, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        
        let requestTokenFunction = functions.httpsCallable(FunctionName.requestAppleCustomToken)
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
        let refreshFunction = functions.httpsCallable(FunctionName.refreshAppleAccessToken)
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
        
        let requestFuction = functions.httpsCallable(FunctionName.requestAppleRefreshToken)
        
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
        let revokeFunction = functions.httpsCallable(FunctionName.revokeAppleAccessToken)
        
        _ = try await revokeFunction.call(["token": token])
    }
}

private extension AppleAuthenticationServiceImpl {
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
}
