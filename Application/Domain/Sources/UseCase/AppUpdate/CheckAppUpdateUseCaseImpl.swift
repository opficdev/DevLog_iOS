//
//  CheckAppUpdateUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 7/22/26.
//

public final class CheckAppUpdateUseCaseImpl: CheckAppUpdateUseCase {
    private let repository: AppVersionRepository

    init(_ repository: AppVersionRepository) {
        self.repository = repository
    }

    public func execute(_ currentVersion: AppVersion) async throws -> Bool {
        let requiredVersionValue = try await repository.fetchRequiredVersion()
        let requiredVersion = try AppVersion(requiredVersionValue)
        return currentVersion < requiredVersion
    }
}
