//
//  GoogleAuthenticationServiceImpl.swift
//  Infra
//
//  Created by opfic on 6/4/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import Foundation
import GoogleSignIn
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
    private let provider = TopViewControllerProvider()
    private let logger = Logger(category: "GoogleAuthService")

    @MainActor
    func signIn() async throws -> AuthDataResponse? {
        logger.info("Starting Google sign in")
        
        guard let topViewController = provider.topViewController() else {
            logger.error("Top view controller not found")
            throw UIError.notFoundTopViewController
        }

        do {
            let signIn = try await GIDSignIn.sharedInstance.signIn(withPresenting: topViewController)

            guard let idToken = signIn.user.idToken?.tokenString else {
                logger.error("ID token not found")
                throw URLError(.badServerResponse)
            }
            
            let accessToken = signIn.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            logger.debug("Signing in with Google credential")
            let result = try await Auth.auth().signIn(with: credential)
            
            if let photoURL = signIn.user.profile?.imageURL(withDimension: 200) {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.photoURL = photoURL
                changeRequest.displayName = signIn.user.profile?.name

                try await changeRequest.commitChanges()
            }

            logger.info("Successfully signed in with Google")
            return result.user.makeResponse(providerID: .google)
        } catch {
            if error.isSocialLoginCancelled { return nil }

            logger.error("Failed to sign in with Google", error: error)
            record(error, code: .signIn)
            throw error
        }
    }

    func signOut(_ uid: String) async throws {
        do {
            let infoRef = store.document(FirestorePath.userData(uid, document: .tokens))
            try? await infoRef.updateData(["fcmToken": FieldValue.delete()])

            GIDSignIn.sharedInstance.signOut()
            try await GIDSignIn.sharedInstance.disconnect()

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
            GIDSignIn.sharedInstance.signOut()
            try await GIDSignIn.sharedInstance.disconnect()
        } catch {
            logger.error("Failed to delete Google auth", error: error)
            record(error, code: .deleteAuth)
            throw error
        }
    }

    @MainActor
    func link(uid: String, email: String) async throws -> Bool {
        do {
            guard let topViewController = provider.topViewController() else {
                throw UIError.notFoundTopViewController
            }

            if GIDSignIn.sharedInstance.hasPreviousSignIn() {
                GIDSignIn.sharedInstance.signOut()
            }

            let signIn = try await GIDSignIn.sharedInstance.signIn(withPresenting: topViewController)

            guard let googleEmail = signIn.user.profile?.email else {
                throw EmailFetchError.emailNotFound
            }

            if googleEmail != email {
                throw EmailFetchError.emailMismatch
            }

            guard let idToken = signIn.user.idToken?.tokenString else {
                throw URLError(.badServerResponse)
            }

            let accessToken = signIn.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            try await user?.link(with: credential)
            return true
        } catch {
            if error.isSocialLoginCancelled { return false }

            logger.error("Failed to link Google account", error: error)
            record(error, code: .link)
            if error.isFirebaseCredentialAlreadyInUse {
                throw DataLayerError.linkCredentialAlreadyInUse
            }
            throw error
        }
    }

    func unlink(_ uid: String) async throws {
        do {
            logger.info("Starting Google disconnect for unlink. uid: \(uid)")
            GIDSignIn.sharedInstance.signOut()
            try await GIDSignIn.sharedInstance.disconnect()

            logger.info("Starting Firebase Google provider unlink. uid: \(uid)")
            _ = try await user?.unlink(fromProvider: AuthProviderID.google.rawValue)
        } catch {
            logger.error("Failed to unlink Google account", error: error)
            record(error, code: .unlink)
            throw error
        }
    }
}

private extension GoogleAuthenticationServiceImpl {
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
