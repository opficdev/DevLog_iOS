//
//  WebPageImageRepositoryImpl.swift
//  DevLog
//
//  Created by opfic on 4/14/26.
//

final class WebPageImageRepositoryImpl: WebPageImageRepository {
    private let store: WebPageImageStore

    init(store: WebPageImageStore) {
        self.store = store
    }

    func fetchDirSizeInBytes() async -> Int64 {
        let store = self.store
        return await Task.detached(priority: .utility) {
            store.dirSizeInBytes()
        }.value
    }

    func clearDirectory() async throws {
        let store = self.store
        try await Task.detached(priority: .utility) {
            try store.clearDirectory()
        }.value
    }
}
