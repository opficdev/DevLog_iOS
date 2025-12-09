//
//  GithubAuthenticationService.swift
//  DevLog
//
//  Created by opfic on 6/4/25.
//

import AuthenticationServices
import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import FirebaseMessaging

final class GithubAuthenticationService: NSObject, AuthenticationService {
    private let store = Firestore.firestore()
    private let functions = Functions.functions(region: "asia-northeast3")
    private let messaging = Messaging.messaging()
    private var user: User? { Auth.auth().currentUser }
    private let providerID = AuthProviderID.gitHub

    func signIn() async throws -> AuthenticationData {
        // 1. GitHub OAuth 로그인 요청
        let authorizationCode = try await requestAuthorizationCode()

        // 2. Firebase Functions를 통해 customToken 발급 요청
        let (accessToken, customToken) = try await requestTokens(authorizationCode: authorizationCode)
        
        // 3. Firebase 로그인
        let result = try await Auth.auth().signIn(withCustomToken: customToken)
        
        // 4. Firebase Auth 사용자 프로필 업데이트
        let githubUser = try await requestUserProfile(accessToken: accessToken)
        
        if let photoURL = githubUser.avatarUrl, let url = URL(string: photoURL) {
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.photoURL = url
            changeRequest.displayName = githubUser.name ?? githubUser.login
            try await changeRequest.commitChanges()
        }
        
        // 5. GitHub 계정과 Firebase Auth 계정 연결
        if !result.user.providerData.contains(where: { $0.providerID == "github.com" }) {
            let credential = OAuthProvider.credential(providerID: AuthProviderID.gitHub, accessToken: accessToken)
            try await result.user.link(with: credential)
        }

        let fcmToken = try await messaging.token()

        return result.user.toData(
            providerID: .gitHub,
            fcmToken: fcmToken,
            accessToken: accessToken
        )
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
        try await revokeAccessToken()

        let deleteFunction = functions.httpsCallable("deleteUserFirestoreData")

        _ = try await deleteFunction.call(["uid": uid])

        try await signOut(uid)
        try await user?.delete()
    }

    func link(uid: String, email: String) async throws {
        let tokensRef = store.document("users/\(uid)/userData/tokens")
        let authorizationCode = try await requestAuthorizationCode()
        let (accessToken, _) = try await requestTokens(authorizationCode: authorizationCode)

        let githubUser = try await requestUserProfile(accessToken: accessToken)

        guard let githubEmail = githubUser.email else {
            try await revokeAccessToken(accessToken: accessToken)
            throw EmailFetchError.emailNotFound
        }

        if githubEmail != email {
            try await revokeAccessToken(accessToken: accessToken)
            throw EmailFetchError.emailMismatch
        }

        try await tokensRef.setData(["githubAccessToken": accessToken], merge: true)

        let credential = OAuthProvider.credential(providerID: AuthProviderID.gitHub, accessToken: accessToken)
        try await user?.link(with: credential)
    }

    func unlink(_ uid: String) async throws {
        try await revokeAccessToken()

        let tokensRef = store.document("users/\(uid)/userData/tokens")

        try await tokensRef.updateData(["githubAccessToken": FieldValue.delete()])

        _ = try await user?.unlink(fromProvider: providerID.rawValue)
    }

    func requestAuthorizationCode() async throws -> String {
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
                    continuation.resume(throwing: URLError(.userCancelledAuthentication))
                    return
                }

                continuation.resume(returning: code)
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false   //  웹에서 깃헙 로그인 후 세션 유지
            
            if !session.start() {
                continuation.resume(throwing: URLError(.userCancelledAuthentication))
            }
        }
    }
    
    // Firebase Function 호출: Custom Token 발급
    func requestTokens(authorizationCode: String) async throws -> (String, String) {
        let requestTokenFunction = functions.httpsCallable("requestGithubTokens")
        let result = try await requestTokenFunction.call(["code": authorizationCode])
        
        if let data = result.data as? [String: Any],
           let accessToken = data["accessToken"] as? String,
           let customToken = data["customToken"] as? String {
            return (accessToken, customToken)
        }
        throw URLError(.badServerResponse)
    }
    
    func revokeAccessToken(accessToken: String? = nil) async throws {
        var param: [String: Any] = [:]
        
        if let accessToken = accessToken {
            param["accessToken"] = accessToken
        }
        
        let revokeFunction = functions.httpsCallable("revokeGithubAccessToken")
        
        _ = try await revokeFunction.call(param)
    }

    // GitHub API로 사용자 프로필 정보 가져오기
    func requestUserProfile(accessToken: String) async throws -> GitHubUser {
        var request = URLRequest(url: URL(string: "https://api.github.com/user")!)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(GitHubUser.self, from: data)
    }
}

extension GithubAuthenticationService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let window = UIApplication.shared.connectedScenes
            .flatMap({ ($0 as? UIWindowScene)?.windows ?? [] })
            .first(where: { $0.isKeyWindow }) else {
                return ASPresentationAnchor()
        }
        return window
    }

    struct GitHubUser: Codable {
        let login: String
        let name: String?
        let avatarUrl: String?
        let email: String?

        enum CodingKeys: String, CodingKey {
            case login
            case name
            case avatarUrl = "avatar_url"
            case email
        }
    }

}
