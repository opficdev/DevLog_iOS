//
//  ITunesAppVersionServiceImpl.swift
//  Infra
//
//  Created by opfic on 7/24/26.
//

import Data
import Foundation
import Nexa

final class ITunesAppVersionServiceImpl: AppVersionConfigurationService {
    private enum InfoKey {
        static let lookupURL = "APP_STORE_LOOKUP_URL"
    }

    func fetchRequiredVersion() async throws -> String {
        let url = try Self.lookupURL(
            from: Bundle.main.object(
                forInfoDictionaryKey: InfoKey.lookupURL
            ) as? String
        )
        let client = NXAPIClient(
            configuration: NXClientConfiguration(baseURL: url)
        )
        let lookupResponse = try await client.send(
            ITunesLookupEndpoint(
                timestamp: Int(Date().timeIntervalSince1970)
            )
        )

        guard let version = lookupResponse.version else {
            throw AppVersionServiceError.missingVersion
        }

        return try Self.normalizedVersion(version)
    }

    static func lookupURL(from lookupURLString: String?) throws -> URL {
        guard let lookupURLString = normalizedLookupURLString(
            lookupURLString
        ) else {
            throw AppVersionServiceError.missingLookupURL
        }

        guard var components = URLComponents(string: lookupURLString),
              components.scheme?.lowercased() == "https",
              components.host != nil else {
            throw AppVersionServiceError.invalidLookupURL
        }

        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == ITunesLookupEndpoint.timestampQueryKey }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw AppVersionServiceError.invalidLookupURL
        }

        return url
    }

    private static func normalizedLookupURLString(
        _ lookupURLString: String?
    ) -> String? {
        guard let lookupURLString else { return nil }

        let value = lookupURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.hasPrefix("$(") else {
            return nil
        }

        return value
    }

    static func normalizedVersion(_ version: String) throws -> String {
        let value = version.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = value.split(
            separator: ".",
            omittingEmptySubsequences: false
        )
        let isValid = !components.isEmpty && components.allSatisfy { component in
            !component.isEmpty && component.unicodeScalars.allSatisfy {
                48 <= $0.value && $0.value <= 57
            }
        }

        guard isValid else {
            throw AppVersionServiceError.invalidVersion
        }

        return value
    }
}
