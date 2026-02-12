//
//  AuthService.swift
//  DevLog
//
//  Created by 최윤진 on 11/29/25.
//

import FirebaseAuth
import FirebaseFirestore

final class AuthService {
    private let store = Firestore.firestore()
    private let logger = Logger(category: "AuthService")

    var uid: String? {
        Auth.auth().currentUser?.uid
    }

    var providerIDs: [String]? {
        Auth.auth().currentUser?.providerData.map { $0.providerID }
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
}
