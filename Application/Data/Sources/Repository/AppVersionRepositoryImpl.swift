//
//  AppVersionRepositoryImpl.swift
//  Data
//
//  Created by opfic on 7/22/26.
//

import Domain

final class AppVersionRepositoryImpl: AppVersionRepository {
    private let service: AppStoreVersionService

    init(service: AppStoreVersionService) {
        self.service = service
    }

    func fetchLatestVersion() async throws -> String {
        try await service.fetchLatestVersion()
    }
}
