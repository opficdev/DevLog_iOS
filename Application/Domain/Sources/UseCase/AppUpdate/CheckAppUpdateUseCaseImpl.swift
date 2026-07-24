//
//  CheckAppUpdateUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 7/22/26.
//

import Foundation

public final class CheckAppUpdateUseCaseImpl: CheckAppUpdateUseCase {
    private let repository: AppVersionRepository

    init(_ repository: AppVersionRepository) {
        self.repository = repository
    }

    public func execute() async throws -> Bool {
        let latestVersionValue = try await repository.fetchLatestVersion()
        let latestVersion = try AppVersion(latestVersionValue)
        let currentVersion = try currentVersion()
        return currentVersion < latestVersion
    }

    private func currentVersion() throws -> AppVersion {
        guard let marketingVersion = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String else {
            throw DomainLayerError.invalidData(context: "appVersion")
        }

        return try AppVersion(marketingVersion)
    }
}
