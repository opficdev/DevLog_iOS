//
//  AppVersionRepositoryImpl.swift
//  Data
//
//  Created by opfic on 7/22/26.
//

import Domain

final class AppVersionRepositoryImpl: AppVersionRepository {
    private let service: AppVersionConfigurationService

    init(service: AppVersionConfigurationService) {
        self.service = service
    }

    func fetchRequiredVersion() async throws -> String {
        try await service.fetchRequiredVersion()
    }
}
