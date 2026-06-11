//
//  ProfileImageDataRepositoryImpl.swift
//  DevLogData
//
//  Created by opfic on 6/11/26.
//

import Foundation
import DevLogDomain

public final class ProfileImageDataRepositoryImpl: ProfileImageDataRepository {
    private let service: ProfileImageDataService
    private let store: MemoryCacheStore

    public init(
        service: ProfileImageDataService,
        store: MemoryCacheStore
    ) {
        self.service = service
        self.store = store
    }

    public func fetchImageData(from url: URL) async throws -> Data {
        do {
            let data = try await service.fetchImageData(from: url)
            store.setValue(data, forKey: Self.cacheKey(for: url))
            return data
        } catch {
            if let data: Data = store.value(forKey: Self.cacheKey(for: url)) {
                return data
            }
            throw error
        }
    }

    private static func cacheKey(for url: URL) -> String {
        "profileImageData:\(url.absoluteString)"
    }
}
