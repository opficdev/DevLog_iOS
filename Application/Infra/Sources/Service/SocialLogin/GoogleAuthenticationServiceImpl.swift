//
//  GoogleAuthenticationServiceImpl.swift
//  Infra
//
//  Created by opfic on 6/4/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import Core
import Data

final class GoogleAuthenticationServiceImpl: AuthenticationService {
    private enum CrashlyticsError {
        static let domain = "DevLogInfra.GoogleAuthenticationServiceImpl"

        enum Code: Int {
            case signIn = 1
            case signOut
            case deleteAuth
            case link
            case unlink
        }
    }

    private let store = FirebaseConfiguration.firestore
    private let messaging = Messaging.messaging()
    private var user: User? { Auth.auth().currentUser }
    private let logger = Logger(category: "GoogleAuthService")

    func signIn() async throws -> AuthDataResponse? {
        logger.info("Starting Google sign in")

        do {
            let request = try await OAuthAuthenticationTicketRequester.request(
                endpoint: .requestGoogleSignInSession,
                requiresAuthentication: false
            )
            let response = try await FunctionAPIClient.shared.send(
                .requestGoogleCustomToken,
                payload: request,
                requiresAuthentication: false
            )

            logger.debug("Signing in with custom token")
            let result = try await Auth.auth().signIn(withCustomToken: response.customToken)

            logger.info("Successfully signed in with Google")
            return result.user.makeResponse(providerID: .google)
        } catch {
            if error.isSocialLoginCancelled { return nil }

            let mappedError = mapGoogleAPIError(error)
            logger.error("Failed to sign in with Google", error: mappedError)
            record(mappedError, code: .signIn)
            throw mappedError
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
                    logger.error("Failed to delete FCM token while signing out with Google", error: error)
                }
            }

            try Auth.auth().signOut()
        } catch {
            logger.error("Failed to sign out with Google", error: error)
            record(error, code: .signOut)
            throw error
        }
    }

    func deleteAuth(_ uid: String) async throws {
        do {
            try await FunctionAPIClient.shared.send(.revokeGoogleAccessToken)
        } catch {
            logger.error("Failed to delete Google auth", error: error)
            record(error, code: .deleteAuth)
            throw error
        }
    }

    func link(uid: String) async throws -> Bool {
        logger.info("Linking Google account for user: \(uid)")

        do {
            let request = try await OAuthAuthenticationTicketRequester.request(
                endpoint: .requestGoogleAccountLinkSession,
                requiresAuthentication: true
            )
            try await FunctionAPIClient.shared.send(
                .linkGoogleAccount,
                payload: request
            )
            try await user?.reload()

            logger.info("Successfully linked Google account")
            return true
        } catch {
            if error.isSocialLoginCancelled { return false }

            let mappedError = mapGoogleAPIError(error)
            logger.error("Failed to link Google account", error: mappedError)
            record(mappedError, code: .link)
            throw mappedError
        }
    }

    func unlink(_ uid: String) async throws {
        do {
            logger.info("Unlinking Google account for user: \(uid)")
            try await FunctionAPIClient.shared.send(.unlinkGoogleAccount)
            try await user?.reload()
        } catch {
            let mappedError = mapGoogleAPIError(error)
            logger.error("Failed to unlink Google account", error: mappedError)
            record(mappedError, code: .unlink)
            throw mappedError
        }
    }
}

private extension GoogleAuthenticationServiceImpl {
    func mapGoogleAPIError(_ error: Error) -> Error {
        if let emailError = error.apiEmailError {
            return emailError
        }

        switch error.apiAuthenticationError {
        case .providerLinkConflict:
            return DataLayerError.linkCredentialAlreadyInUse
        case .lastProvider:
            return DataLayerError.failedToUnlinkLastProvider
        case .none:
            return error
        }
    }

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
