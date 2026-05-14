//
//  AuthServiceImpl.swift
//  DevLog
//
//  Created by 최윤진 on 11/29/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import DevLogDataCommon
import DevLogDataDTO
import DevLogDataProtocol

final class AuthServiceImpl: AuthService {
    private let store = Firestore.firestore()
    private let messaging = Messaging.messaging()
    private let logger = Logger(category: "AuthServiceImpl")
    private let subject = CurrentValueSubject<Bool, Never>(Auth.auth().currentUser != nil)
    private var handler: AuthStateDidChangeListenerHandle?
    private var isCompletingSignIn = false

    var uid: String? {
        Auth.auth().currentUser?.uid
    }

    var providerIDs: [String] {
        Auth.auth().currentUser?.providerData.map { $0.providerID } ?? []
    }

    var currentUserEmail: String? {
        Auth.auth().currentUser?.email
    }

    var providerCount: Int {
        Auth.auth().currentUser?.providerData.count ?? 0
    }

    init() {
        handler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            let signedIn = user != nil
            self.logger.info("Firebase auth state changed. signedIn: \(signedIn)")

            if signedIn && self.isCompletingSignIn {
                self.logger.info("Delaying signed-in publication until user bootstrap finishes")
                return
            }

            self.subject.send(signedIn)
        }
    }

    deinit {
        guard let handler else { return }
        Auth.auth().removeStateDidChangeListener(handler)
    }

    func observeSignedIn() -> AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    func beginSignIn() {
        logger.info("Beginning sign-in bootstrap")
        isCompletingSignIn = true
        subject.send(false)
    }

    func completeSignIn() {
        logger.info("Completing sign-in bootstrap")
        isCompletingSignIn = false
        subject.send(Auth.auth().currentUser != nil)
    }

    func cancelSignIn() {
        logger.info("Cancelling sign-in bootstrap")
        isCompletingSignIn = false
        subject.send(Auth.auth().currentUser != nil)
    }

    func getProviderID() async throws -> String? {
        logger.info("Fetching current provider ID")
        
        guard let uid = uid else {
            logger.warning("No user ID available")
            return nil
        }

        do {
            let document = try await store
                .document(FirestorePath.userData(uid, document: .info))
                .getDocument()

            let providerID = document.data()?["currentProvider"] as? String
            logger.info("Successfully fetched provider ID: \(providerID ?? "nil")")
            return providerID
        } catch {
            logger.error("Failed to fetch provider ID", error: error)
            throw error
        }
    }

    func deleteCurrentUser() async throws {
        logger.info("Deleting FirebaseAuth current user")

        guard let currentUser = Auth.auth().currentUser else {
            logger.warning("No current user to delete")
            throw AuthError.notAuthenticated
        }

        do {
            try await currentUser.delete()
        } catch {
            logger.error("Failed to delete FirebaseAuth current user", error: error)
            throw error
        }
    }

    func clearCurrentSession() async throws {
        logger.info("Clearing current auth session")

        do {
            try await messaging.deleteToken()
        } catch {
            logger.error("Failed to delete FCM token while clearing session", error: error)
        }

        do {
            try Auth.auth().signOut()
        } catch {
            logger.error("Failed to sign out while clearing session", error: error)
            throw error
        }
    }

    func isCredentialAlreadyInUseError(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain,
              let authErrorCode = AuthErrorCode(rawValue: nsError.code) else {
            return false
        }
        return authErrorCode == .credentialAlreadyInUse
    }
}
