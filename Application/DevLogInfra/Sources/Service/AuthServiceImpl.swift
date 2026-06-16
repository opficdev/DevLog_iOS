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
    private enum CrashlyticsError {
        static let domain = "DevLogInfra.AuthServiceImpl"

        enum Code: Int {
            case getProviderID = 1
            case deleteCurrentUser
            case deleteMessagingToken
            case signOut
        }
    }

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
            self?.handleAuthStateChange(user)
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
            record(error, code: .getProviderID)
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
            record(error, code: .deleteCurrentUser)
            throw error
        }
    }

    func clearCurrentSession() async throws {
        logger.info("Clearing current auth session")

        do {
            try await messaging.deleteToken()
        } catch {
            logger.error("Failed to delete FCM token while clearing session", error: error)
            record(error, code: .deleteMessagingToken)
        }

        do {
            try Auth.auth().signOut()
        } catch {
            logger.error("Failed to sign out while clearing session", error: error)
            record(error, code: .signOut)
            throw error
        }
    }

}

private extension AuthServiceImpl {
    private static func record(_ error: Error, code: CrashlyticsError.Code) {
        FirebaseCrashlyticsHelper.record(
            error,
            domain: CrashlyticsError.domain,
            code: code.rawValue
        )
    }

    private func record(_ error: Error, code: CrashlyticsError.Code) {
        Self.record(error, code: code)
    }

    func handleAuthStateChange(_ user: User?) {
        let signedIn = user != nil
        logger.info("Firebase auth state changed. signedIn: \(signedIn)")

        if signedIn && isCompletingSignIn {
            logger.info("Delaying signed-in publication until user bootstrap finishes")
            return
        }

        subject.send(signedIn)
    }
}
