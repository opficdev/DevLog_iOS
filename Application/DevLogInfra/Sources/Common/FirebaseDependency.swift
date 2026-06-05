//
//  FirebaseDependency.swift
//  DevLogInfra
//
//  Created by opfic on 6/5/26.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import FirebaseMessaging

struct FirebaseDependency<Value> {
    private let value: Value

    init(value: Value) {
        self.value = value
    }
}

extension FirebaseDependency where Value == Firestore {
    func document(_ path: String) -> DocumentReference {
        value.document(path)
    }
}

extension FirebaseDependency where Value == Functions {
    func httpsCallable(_ name: some RawRepresentable<String>) -> HTTPSCallable {
        value.httpsCallable(name)
    }
}

extension FirebaseDependency where Value == Messaging {
    func token() async throws -> String {
        try await value.token()
    }

    func deleteToken() async throws {
        try await value.deleteToken()
    }
}

extension FirebaseDependency where Value == AuthStateDidChangeListenerHandle {
    func removeAuthStateDidChangeListener() {
        Auth.auth().removeStateDidChangeListener(value)
    }
}
