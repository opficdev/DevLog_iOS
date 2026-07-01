//
//  WebPageImageStoreImplTests.swift
//  PersistenceTests
//
//  Created by opfic on 6/3/26.
//

import Foundation
import Testing
@testable import Persistence

@Suite(.serialized)
struct WebPageImageStoreImplTests {
    @Test("웹페이지 이미지는 저장되고 삭제된다")
    func 웹페이지_이미지는_저장되고_삭제된다() async throws {
        let store = WebPageImageStoreImpl()
        let fileManager = FileManager.default
        try await store.clearDirectory()
        let url = try #require(URL(string: "https://example.com/image"))
        let data = Data("image-data".utf8)

        let fileURL = try await store.saveImage(data, for: url)

        let savedData = try #require(fileManager.contents(atPath: fileURL.path))
        let directorySize = await store.dirSizeInBytes()
        #expect(fileURL.deletingLastPathComponent().lastPathComponent == "webPageImages")
        #expect(savedData == data)
        #expect(0 < directorySize)

        let removed = try await store.removeImage(for: url)
        let removedAgain = try await store.removeImage(for: url)

        #expect(removed)
        #expect(!removedAgain)
        #expect(!fileManager.fileExists(atPath: fileURL.path))

        try await store.clearDirectory()
    }

    @Test("웹페이지 이미지 디렉터리 삭제는 저장된 이미지를 모두 제거한다")
    func 웹페이지_이미지_디렉터리_삭제는_저장된_이미지를_모두_제거한다() async throws {
        let store = WebPageImageStoreImpl()
        try await store.clearDirectory()
        let firstURL = try #require(URL(string: "https://example.com/first"))
        let secondURL = try #require(URL(string: "https://example.com/second"))

        _ = try await store.saveImage(Data("first".utf8), for: firstURL)
        _ = try await store.saveImage(Data("second".utf8), for: secondURL)
        try await store.clearDirectory()

        let directorySize = await store.dirSizeInBytes()
        #expect(directorySize == 0)
    }

    @Test("같은 store를 공유하는 객체의 저장은 트랜잭션 단위로 반영된다")
    func 같은_store를_공유하는_객체의_저장은_트랜잭션_단위로_반영된다() async throws {
        let store = WebPageImageStoreImpl()
        let firstClient = WebPageImageStoreClient(store: store)
        let secondClient = WebPageImageStoreClient(store: store)
        try await store.clearDirectory()
        let url = try #require(URL(string: "https://example.com/\(UUID().uuidString)"))
        let largeData = Data(repeating: 1, count: 64 * 1024 * 1024)
        let smallData = Data("latest".utf8)
        let startedAt = ContinuousClock.now

        // 동일한 Impl 인스턴스를 공유하는 두 객체가 접근하는 형태의 결과 기반 테스트다.
        // 첫 번째 큰 저장 작업이 먼저 큐에 들어갈 시간을 준 뒤 두 번째 작은 저장을 요청하고,
        // 최종 파일이 작은 데이터라면 앞 작업 전체가 끝난 뒤 뒤 작업이 반영된 것으로 본다.
        // 각 작업의 완료 시점은 호출자 관점에서 saveImage await가 반환된 시점으로 기록한다.
        let largeSaveTask = Task {
            try await firstClient.saveImage(largeData, for: url, name: "large", since: startedAt)
        }
        try await Task.sleep(nanoseconds: 10_000_000)

        let smallSaveMeasurement = try await secondClient.saveImage(smallData, for: url, name: "small", since: startedAt)
        let largeSaveMeasurement = try await largeSaveTask.value
        let savedData = try Data(contentsOf: smallSaveMeasurement.fileURL)

        print(saveSummary(largeSaveMeasurement))
        print(saveSummary(smallSaveMeasurement))

        #expect(savedData == smallData)

        try await store.clearDirectory()
    }
}

private struct WebPageImageStoreClient {
    let store: WebPageImageStoreImpl

    func saveImage(
        _ data: Data,
        for url: URL,
        name: String,
        since startedAt: ContinuousClock.Instant
    ) async throws -> WebPageImageStoreSaveMeasurement {
        let requestedAt = startedAt.duration(to: .now)
        let fileURL = try await store.saveImage(data, for: url)
        let finishedAt = startedAt.duration(to: .now)

        return WebPageImageStoreSaveMeasurement(
            name: name,
            fileURL: fileURL,
            requestedAt: requestedAt,
            finishedAt: finishedAt
        )
    }
}

private struct WebPageImageStoreSaveMeasurement {
    let name: String
    let fileURL: URL
    let requestedAt: Duration
    let finishedAt: Duration
}

private func saveSummary(_ measurement: WebPageImageStoreSaveMeasurement) -> String {
    "\(measurement.name) save requested: \(millisecondsString(measurement.requestedAt))ms, finished: \(millisecondsString(measurement.finishedAt))ms"
}

private func millisecondsString(_ duration: Duration) -> String {
    let components = duration.components
    let milliseconds = Double(components.seconds) * 1_000 + Double(components.attoseconds) / 1_000_000_000_000_000
    return String(format: "%.3f", milliseconds)
}
