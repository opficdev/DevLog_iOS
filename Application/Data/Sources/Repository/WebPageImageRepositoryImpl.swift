//
//  WebPageImageRepositoryImpl.swift
//  Data
//
//  Created by opfic on 4/14/26.
//

import Domain

final class WebPageImageRepositoryImpl: WebPageImageRepository {
    private let authService: AuthService
    private let store: WebPageImageStore

    init(
        authService: AuthService,
        store: WebPageImageStore
    ) {
        self.authService = authService
        self.store = store
    }

    func fetchDirSizeInBytes() async -> Int64 {
        await store.dirSizeInBytes(accountID: authService.uid)
    }

    func clearDirectory() async throws {
        try await store.clearDirectory(accountID: authService.uid)
    }
}
