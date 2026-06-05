//
//  AuthServiceImpl.swift
//  DevLogInfra
//
//  Created by 최윤진 on 11/29/25.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import DevLogCore
import DevLogData

final class AuthServiceImpl: AuthService {
    private let store = FirebaseDependency(value: Firestore.firestore())
    private let messaging = FirebaseDependency(value: Messaging.messaging())
    private let logger = Logger(category: "AuthServiceImpl")
    private let authStatePublisher: AuthStatePublisher

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
        authStatePublisher = AuthStatePublisher(logger: logger)
    }

    func observeSignedIn() -> AnyPublisher<Bool, Never> {
        authStatePublisher.observeSignedIn()
    }

    func beginSignIn() {
        logger.info("Beginning sign-in bootstrap")
        authStatePublisher.beginSignIn()
    }

    func completeSignIn() {
        logger.info("Completing sign-in bootstrap")
        authStatePublisher.completeSignIn()
    }

    func cancelSignIn() {
        logger.info("Cancelling sign-in bootstrap")
        authStatePublisher.cancelSignIn()
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
            throw DataLayerError.notAuthenticated
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

}

private final class AuthStatePublisher: @unchecked Sendable {
    private let logger: Logger
    private let subject: CurrentValueSubject<Bool, Never>
    private let lock = NSLock()
    private var handler: FirebaseDependency<AuthStateDidChangeListenerHandle>?
    private var isCompletingSignIn = false

    init(logger: Logger) {
        self.logger = logger
        self.subject = CurrentValueSubject<Bool, Never>(Auth.auth().currentUser != nil)
        self.handler = FirebaseDependency(
            value: Auth.auth().addStateDidChangeListener { [weak self] _, user in
                self?.handleAuthStateChange(user)
            }
        )
    }

    deinit {
        guard let handler else { return }
        handler.removeAuthStateDidChangeListener()
    }

    func observeSignedIn() -> AnyPublisher<Bool, Never> {
        lock.lock()
        defer { lock.unlock() }
        return subject.eraseToAnyPublisher()
    }

    func beginSignIn() {
        lock.lock()
        isCompletingSignIn = true
        subject.send(false)
        lock.unlock()
    }

    func completeSignIn() {
        lock.lock()
        isCompletingSignIn = false
        subject.send(Auth.auth().currentUser != nil)
        lock.unlock()
    }

    func cancelSignIn() {
        lock.lock()
        isCompletingSignIn = false
        subject.send(Auth.auth().currentUser != nil)
        lock.unlock()
    }

    private func handleAuthStateChange(_ user: User?) {
        lock.lock()
        defer { lock.unlock() }

        let signedIn = user != nil
        logger.info("Firebase auth state changed. signedIn: \(signedIn)")

        if signedIn && isCompletingSignIn {
            logger.info("Delaying signed-in publication until user bootstrap finishes")
            return
        }

        subject.send(signedIn)
    }
}
