//
//  FirebaseConfiguration.swift
//  Infra
//
//  Created by opfic on 6/26/26.
//

import FirebaseFirestore
import Foundation

public enum FirebaseConfiguration {
    private enum InfoKey {
        static let databaseID = "FIRESTORE_DATABASE_ID"
        static let functionAPIBaseURL = "FUNCTION_API_BASE_URL"
    }

    static let defaultDatabaseID = "staging"

    public static var databaseID: String {
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

    static func functionAPIBaseURL() throws -> URL {
        if let value = resolvedValue(for: InfoKey.functionAPIBaseURL),
           let url = URL(string: value) {
            return url
        }

        throw URLError(.badURL)
    }

    private static func resolvedValue(for key: String) -> String? {
        let environmentValue = ProcessInfo.processInfo.environment[key]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let environmentValue, !environmentValue.isEmpty {
            return environmentValue
        }

        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.hasPrefix("$(") else {
            return nil
        }

        return value
    }
}
