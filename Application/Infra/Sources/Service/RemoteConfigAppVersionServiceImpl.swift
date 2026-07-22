//
//  RemoteConfigAppVersionServiceImpl.swift
//  Infra
//
//  Created by opfic on 7/22/26.
//

import Data
import FirebaseRemoteConfig
import Foundation

enum AppVersionConfigurationError: Error {
    case missingRequiredVersion
}

final class RemoteConfigAppVersionServiceImpl: AppVersionConfigurationService {
    private enum Key {
        static let requiredVersion = "ios_required_version"
    }

    private let remoteConfig = RemoteConfig.remoteConfig()

    init() {
        remoteConfig.setDefaults([
            Key.requiredVersion: "" as NSString
        ])
    }

    func fetchRequiredVersion() async throws -> String {
        _ = try? await remoteConfig.fetchAndActivate()

        guard let version = normalizedRequiredVersion() else {
            throw AppVersionConfigurationError.missingRequiredVersion
        }
        return version
    }

    private func normalizedRequiredVersion() -> String? {
        let version = remoteConfig
            .configValue(forKey: Key.requiredVersion)
            .stringValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return version.isEmpty ? nil : version
    }
}
