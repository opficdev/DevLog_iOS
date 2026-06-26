//
//  FirebaseConfiguration.swift
//  DevLogInfra
//
//  Created by opfic on 6/26/26.
//

import FirebaseFirestore
import FirebaseFunctions
import Foundation

enum FirebaseConfiguration {
    private enum InfoKey {
        static let databaseID = "FIRESTORE_DATABASE_ID"
    }

    private enum CallablePayloadKey {
        static let databaseID = "databaseID"
    }

    static let defaultDatabaseID = "staging"

    static var databaseID: String {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: InfoKey.databaseID) as? String else {
            return defaultDatabaseID
        }

        let databaseID = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if databaseID.isEmpty || databaseID.hasPrefix("$(") {
            return defaultDatabaseID
        }

        return databaseID
    }

    static var firestore: Firestore {
        Firestore.firestore(database: databaseID)
    }

    static var functions: Functions {
        Functions.functions(region: "asia-northeast3")
    }

    static func callablePayload(_ payload: [String: Any] = [:]) -> [String: Any] {
        var payload = payload
        payload[CallablePayloadKey.databaseID] = databaseID
        return payload
    }
}
