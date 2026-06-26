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

    static let defaultDatabaseID = "staging"

    static var databaseID: String {
        let environmentValue = ProcessInfo.processInfo.environment[InfoKey.databaseID]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let environmentValue, !environmentValue.isEmpty {
            return environmentValue
        }

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
}
