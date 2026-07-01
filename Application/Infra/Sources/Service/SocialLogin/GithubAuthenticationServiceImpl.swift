//
//  GithubAuthenticationServiceImpl.swift
//  Infra
//
//  Created by opfic on 6/4/25.
//

import AuthenticationServices
import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import Nexa
import Core
import Data

final class GithubAuthenticationServiceImpl: NSObject, AuthenticationService {
    private enum CrashlyticsError {
        static let domain = "DevLogInfra.GithubAuthenticationServiceImpl"

        enum Code: Int {
            case signIn = 1
            case signOut
            case deleteAuth
            case link
            case unlink
        }
    }

    private enum GitHubAPI {
        static let baseURL = URL(string: "https://api.github.com")!
        static let acceptHeader = "application/vnd.github.v3+json"
    }

    private let store = FirebaseConfiguration.firestore
    private let messaging = Messaging.messaging()
    private var user: User? { Auth.auth().currentUser }
    private let providerID = AuthProviderID.gitHub
    private let provider = TopViewControllerProvider()
    private let logger = Logger(category: "GithubAuthService")
    private let gitHubApiClient = NXAPIClient(
        configuration: NXClientConfiguration(
            baseURL: GitHubAPI.baseURL,
            headers: ["Accept": GitHubAPI.acceptHeader]
        )
    )

    func signIn() async throws -> AuthDataResponse? {
        logger.info("Starting GitHub sign in")
        
        do {
            // 1. GitHub OAuth 로그인 요청
            logger.debug("Requesting authorization code")
            let authorizationCode = try await requestAuthorizationCode()

            // 2. Firebase Functions를 통해 customToken 발급 요청
            logger.debug("Requesting tokens from Firebase Function")
            let (accessToken, customToken) = try await requestTokens(authorizationCode: authorizationCode)
            
            // 3. Firebase 로그인
            logger.debug("Signing in with custom token")
            let result = try await Auth.auth().signIn(withCustomToken: customToken)
        
            // 4. Firebase Auth 사용자 프로필 업데이트
            let githubUser = try await requestUserProfile(accessToken: accessToken)

            if let photoURL = githubUser.avatarURL, let url = URL(string: photoURL) {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.photoURL = url
                changeRequest.displayName = githubUser.name ?? githubUser.login
                try await changeRequest.commitChanges()
            }
        
            // 5. GitHub 계정과 Firebase Auth 계정 연결
            if !result.user.providerData.contains(where: { $0.providerID == providerID.rawValue }) {
                let credential = OAuthProvider.credential(providerID: providerID, accessToken: accessToken)
                try await result.user.link(with: credential)
            }

            logger.info("Successfully signed in with GitHub")
            return result.user.makeResponse(
                providerID: .gitHub,
                accessToken: accessToken
            )
        } catch {
            if error.isSocialLoginCancelled { return nil }

            logger.error("Failed to sign in with GitHub", error: error)
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
                    logger.error("Failed to delete FCM token while signing out with GitHub", error: error)
                }
            }

            try Auth.auth().signOut()
        } catch {
            logger.error("Failed to sign out with GitHub", error: error)
            record(error, code: .signOut)
            throw error
        }
    }

    func deleteAuth(_ uid: String) async throws {
        do {
            try await revokeAccessToken()
        } catch {
            logger.error("Failed to delete GitHub auth", error: error)
            record(error, code: .deleteAuth)
            throw error
        }
    }

    func link(uid: String, email: String) async throws -> Bool {
        logger.info("Linking GitHub account for user: \(uid)")
        
        do {
            let tokensRef = store.document(FirestorePath.userData(uid, document: .tokens))
            let authorizationCode = try await requestAuthorizationCode()
            let (accessToken, _) = try await requestTokens(authorizationCode: authorizationCode)

            let githubUser = try await requestUserProfile(accessToken: accessToken)

            guard let githubEmail = githubUser.email else {
                logger.error("GitHub email not found")
                try await revokeAccessToken(accessToken: accessToken)
                throw EmailFetchError.emailNotFound
            }

            if githubEmail != email {
                logger.error("Email mismatch - Expected: \(email), Got: \(githubEmail)")
                try await revokeAccessToken(accessToken: accessToken)
                throw EmailFetchError.emailMismatch
            }

            try await tokensRef.setData(["githubAccessToken": accessToken], merge: true)

            let credential = OAuthProvider.credential(providerID: providerID, accessToken: accessToken)
            try await user?.link(with: credential)
            
            logger.info("Successfully linked GitHub account")
            return true
        } catch {
            if error.isSocialLoginCancelled { return false }

            logger.error("Failed to link GitHub account", error: error)
            record(error, code: .link)
            if error.isFirebaseCredentialAlreadyInUse {
                throw DataLayerError.linkCredentialAlreadyInUse
            }
            throw error
        }
    }

    func unlink(_ uid: String) async throws {
        do {
            logger.info("Starting GitHub access token revocation for unlink. uid: \(uid)")
            try await revokeAccessToken()

            let tokensRef = store.document(FirestorePath.userData(uid, document: .tokens))

            logger.info("Starting GitHub access token deletion from Firestore for unlink. uid: \(uid)")
            try await tokensRef.updateData(["githubAccessToken": FieldValue.delete()])

            logger.info("Starting Firebase GitHub provider unlink. uid: \(uid)")
            _ = try await user?.unlink(fromProvider: providerID.rawValue)
        } catch {
            logger.error("Failed to unlink GitHub account", error: error)
            record(error, code: .unlink)
            throw error
        }
    }

    @MainActor
    private func requestAuthorizationCode() async throws -> String {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GITHUB_CLIENT_ID") as? String,
              let redirectURL = Bundle.main.object(forInfoDictionaryKey: "APP_REDIRECT_URL") as? String,
              let urlComponents = URLComponents(string: redirectURL),
              let callbackURLScheme = urlComponents.scheme else {
            throw URLError(.badURL)
        }

        // state: CSRF(사이트 간 요청 위조) 공격 방지용 랜덤 문자열
        let state = UUID().uuidString
        let scope = "read:user user:email"  //  공개된 정보와 이메일 요청
        
        // Use URLComponents for proper encoding
        var components = URLComponents(string: "https://github.com/login/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "redirect_url", value: redirectURL),
            URLQueryItem(name: "state", value: state)
        ]
        
        guard let authURL = components.url else {
            throw URLError(.badURL)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL, callbackURLScheme: callbackURLScheme) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL = callbackURL,
                    let queryItems = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems,
                    let code = queryItems.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }

                // 반환된 state 값 확인 / 받아온 값이 다르면 CSRF 공격 가능성 있음
                guard let returnedState = queryItems.first(where: { $0.name == "state" })?.value,
                    returnedState == state else {
                    continuation.resume(throwing: SocialLoginError.invalidOAuthState)
                    return
                }

                continuation.resume(returning: code)
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false   //  웹에서 깃헙 로그인 후 세션 유지
            
            if !session.start() {
                continuation.resume(throwing: SocialLoginError.failedToStartWebAuthenticationSession)
            }
        }
    }
    
    // Firebase Function 호출: Custom Token 발급
    private func requestTokens(authorizationCode: String) async throws -> (String, String) {
        do {
            let response = try await FunctionAPIClient.shared.send(
                .requestGithubTokens,
                payload: ["code": authorizationCode],
                requiresAuthentication: false
            )
            
            if let accessToken = response.accessToken,
               let customToken = response.customToken {
                return (accessToken, customToken)
            }
            throw TokenError.invalidResponse
        } catch {
            throw mapRequestTokensError(error)
        }
    }
    
    private func revokeAccessToken(accessToken: String? = nil) async throws {
        var param: [String: String] = [:]
        
        if let accessToken = accessToken {
            param["accessToken"] = accessToken
        }
        
        try await FunctionAPIClient.shared.send(
            .revokeGithubAccessToken,
            payload: param
        )
    }

    // GitHub API로 사용자 프로필 정보 가져오기
    private func requestUserProfile(accessToken: String) async throws -> GitHubUser {
        let gitHubUser = try await gitHubApiClient
            .get("/user", as: GitHubUser.self)
            .header("Authorization", "Bearer \(accessToken)")
            .validate(.statusCodes([200]))
            .send()

        if gitHubUser.email != nil {
            return gitHubUser
        }

        let email = try await requestPrimaryVerifiedEmail(accessToken: accessToken)
        return GitHubUser(
            login: gitHubUser.login,
            name: gitHubUser.name,
            avatarURL: gitHubUser.avatarURL,
            email: email
        )
    }

    private func requestPrimaryVerifiedEmail(accessToken: String) async throws -> String? {
        let gitHubEmails = try await gitHubApiClient
            .get("/user/emails", as: [GitHubEmail].self)
            .header("Authorization", "Bearer \(accessToken)")
            .validate(.statusCodes([200]))
            .send()

        if let primaryVerifiedEmail = gitHubEmails.first(where: { $0.primary && $0.verified }) {
            return primaryVerifiedEmail.email
        }

        return gitHubEmails.first(where: { $0.verified })?.email
    }

    private func mapRequestTokensError(_ error: Error) -> Error {
        if let emailFetchError = error.apiEmailFetchError {
            return emailFetchError
        }

        return error
    }
}

private extension GithubAuthenticationServiceImpl {
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

    struct GitHubUser: Codable {
        let login: String
        let name: String?
        let avatarURL: String?
        let email: String?

        enum CodingKeys: String, CodingKey {
            case login
            case name
            case avatarURL = "avatar_url"
            case email
        }
    }

    struct GitHubEmail: Codable {
        let email: String
        let primary: Bool
        let verified: Bool
    }
}

extension GithubAuthenticationServiceImpl: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return provider.keyWindow() ?? ASPresentationAnchor()
    }
}
