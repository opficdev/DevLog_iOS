//
//  ProfileImageDataRepositoryImplTests.swift
//  DataTests
//
//  Created by opfic on 6/11/26.
//

import Foundation
import Testing
@testable import Data

struct ProfileImageDataRepositoryImplTests {
    @Test("캐시가 있어도 원격 이미지 데이터를 다시 요청하고 성공 데이터를 저장한다")
    func 캐시가_있어도_원격_이미지_데이터를_다시_요청하고_성공_데이터를_저장한다() async throws {
        let cachedData = Data([1, 2, 3])
        let remoteData = Data([4, 5, 6])
        let service = ProfileImageDataServiceSpy(data: cachedData)
        let store = ProfileImageMemoryCacheStoreSpy()
        let repository = ProfileImageDataRepositoryImpl(service: service, store: store)
        let url = URL(string: "https://example.com/avatar.png")!

        _ = try await repository.fetchImageData(from: url)
        service.data = remoteData
        let data = try await repository.fetchImageData(from: url)

        #expect(data == remoteData)
        #expect(service.calledURLs == [url, url])
        #expect(store.storedData == remoteData)
    }

    @Test("원격 이미지 요청 실패 시 메모리 캐시 데이터를 반환한다")
    func 원격_이미지_요청_실패_시_메모리_캐시_데이터를_반환한다() async throws {
        let cachedData = Data([1, 2, 3])
        let service = ProfileImageDataServiceSpy(data: cachedData)
        let store = ProfileImageMemoryCacheStoreSpy()
        let repository = ProfileImageDataRepositoryImpl(service: service, store: store)
        let url = URL(string: "https://example.com/avatar.png")!

        _ = try await repository.fetchImageData(from: url)
        service.error = ProfileImageDataRepositoryImplTestsError.serviceFailed
        let data = try await repository.fetchImageData(from: url)

        #expect(data == cachedData)
        #expect(service.calledURLs == [url, url])
    }
}

private final class ProfileImageDataServiceSpy: ProfileImageDataService {
    var data: Data
    var error: Error?
    private(set) var calledURLs: [URL] = []

    init(data: Data) {
        self.data = data
    }

    func fetchImageData(from url: URL) async throws -> Data {
        calledURLs.append(url)

        if let error {
            throw error
        }

        return data
    }
}

private final class ProfileImageMemoryCacheStoreSpy: MemoryCacheStore {
    private var values = [String: Any]()
    private(set) var storedData: Data?

    func value<T: Codable>(forKey key: String) -> T? {
        values[key] as? T
    }

    func setValue<T: Codable>(_ value: T?, forKey key: String) {
        guard let value else {
            values.removeValue(forKey: key)
            return
        }

        values[key] = value
        storedData = value as? Data
    }
}

private enum ProfileImageDataRepositoryImplTestsError: Error {
    case serviceFailed
}
