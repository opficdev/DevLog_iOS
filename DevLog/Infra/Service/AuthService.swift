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

    var uid: String? {
        Auth.auth().currentUser?.uid
    }

    var providerIDs: [String]? {
        Auth.auth().currentUser?.providerData.map { $0.providerID }
    }

    func getProviderID() async throws -> String? {
        guard let uid = uid else { return nil }

        let document = try await store
            .collection("users/\(uid)/userData")
            .document("info")
            .getDocument()

        return document.data()?["currentProvider"] as? String
    }
}
