//
//  AuthService.swift
//  DevLog
//
//  Created by 최윤진 on 11/29/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import FirebaseMessaging

final class AuthService {
    private let store = Firestore.firestore()
    private let functions = Functions.functions(region: "asia-northeast3")
    private let messaging = Messaging.messaging()
    private let logger = Logger(category: "AuthService")

    var uid: String? {
        Auth.auth().currentUser?.uid
    }

    var providerIDs: [String] {
        Auth.auth().currentUser?.providerData.map { $0.providerID } ?? []
    }

    func getProviderID() async throws -> String? {
        logger.info("Fetching current provider ID")
        
        guard let uid = uid else {
            logger.warning("No user ID available")
            return nil
        }

        do {
            let document = try await store
                .collection("users/\(uid)/userData")
                .document("info")
                .getDocument()

            let providerID = document.data()?["currentProvider"] as? String
            logger.info("Successfully fetched provider ID: \(providerID ?? "nil")")
            return providerID
        } catch {
            logger.error("Failed to fetch provider ID", error: error)
            throw error
        }
    }

    func deleteFirestoreUserData() async throws {
        logger.info("Deleting Firestore user data")

        do {
            let deleteFunction = functions.httpsCallable("deleteUserFirestoreData")
            _ = try await deleteFunction.call()
        } catch {
            logger.error("Failed to delete Firestore user data", error: error)
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
}
