//
//  WebPageImageRepositoryImpl.swift
//  DevLog
//
//  Created by opfic on 4/14/26.
//

import DevLogDomain
import DevLogDataCommon
import DevLogDataDTO
import DevLogDataMapper
import DevLogDataProtocol

final class WebPageImageRepositoryImpl: WebPageImageRepository {
    private let store: WebPageImageStore

    init(store: WebPageImageStore) {
        self.store = store
    }

    func fetchDirSizeInBytes() async -> Int64 {
        await store.dirSizeInBytes()
    }

    func clearDirectory() async throws {
        try await store.clearDirectory()
    }
}
