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

    func fetchDirSizeInBytes() -> Int64 {
        store.dirSizeInBytes()
    }

    func clearDirectory() throws {
        try store.clearDirectory()
    }
}
