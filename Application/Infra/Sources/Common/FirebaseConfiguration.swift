//
//  FirebaseConfiguration.swift
//  Infra
//
//  Created by opfic on 6/26/26.
//

import FirebaseFirestore
import Foundation

enum FirebaseConfigurationError: Error, Equatable {
    case unresolvedValue(String)
}

public enum FirebaseConfiguration {
    private enum InfoKey {
        static let databaseID = "FIRESTORE_DATABASE_ID"
        static let functionAPIBaseURL = "FUNCTION_API_BASE_URL"
    }

    public static var databaseID: String {
        do {
            return try resolveDatabaseID(
                environmentValue: ProcessInfo.processInfo.environment[InfoKey.databaseID],
                bundleValue: Bundle.main.object(forInfoDictionaryKey: InfoKey.databaseID) as? String
            )
        } catch {
            preconditionFailure("\(InfoKey.databaseID) is missing or unresolved.")
        }
    }

    static var firestore: Firestore {
        Firestore.firestore(database: databaseID)
    }

    static func functionAPIBaseURL() throws -> URL {
        try resolveFunctionAPIBaseURL(
            environmentValue: ProcessInfo.processInfo.environment[InfoKey.functionAPIBaseURL],
            bundleValue: Bundle.main.object(forInfoDictionaryKey: InfoKey.functionAPIBaseURL) as? String
        )
    }

    static func resolveDatabaseID(
        environmentValue: String?,
        bundleValue: String?
    ) throws -> String {
        guard let value = resolvedValue(
            environmentValue: environmentValue,
            bundleValue: bundleValue
        ) else {
            throw FirebaseConfigurationError.unresolvedValue(InfoKey.databaseID)
        }

        return value
    }

    static func resolveFunctionAPIBaseURL(
        environmentValue: String?,
        bundleValue: String?
    ) throws -> URL {
        guard let value = resolvedValue(
            environmentValue: environmentValue,
            bundleValue: bundleValue
        ),
        let url = URL(string: value),
        let scheme = url.scheme?.lowercased(),
        ["http", "https"].contains(scheme),
        url.host != nil else {
            throw URLError(.badURL)
        }

        return url
    }

    private static func resolvedValue(
        environmentValue: String?,
        bundleValue: String?
    ) -> String? {
        normalizedValue(environmentValue) ?? normalizedValue(bundleValue)
    }

    private static func normalizedValue(_ rawValue: String?) -> String? {
        guard let rawValue else { return nil }
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.hasPrefix("$(") else {
            return nil
        }

        return value
    }
}
