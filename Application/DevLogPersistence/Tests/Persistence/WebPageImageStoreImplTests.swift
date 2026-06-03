//
//  WebPageImageStoreImplTests.swift
//  DevLogPersistenceTests
//
//  Created by opfic on 6/3/26.
//

import Foundation
import Testing
@testable import DevLogPersistence

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

    @Test("동시 저장 요청은 요청 순서대로 같은 파일을 갱신한다")
    func 동시_저장_요청은_요청_순서대로_같은_파일을_갱신한다() async throws {
        let store = WebPageImageStoreImpl()
        try await store.clearDirectory()
        let url = try #require(URL(string: "https://example.com/\(UUID().uuidString)"))
        let firstData = Data(repeating: 1, count: 64 * 1024 * 1024)
        let secondData = Data("latest".utf8)

        let firstSaveTask = Task {
            try await store.saveImage(firstData, for: url)
        }
        try await Task.sleep(nanoseconds: 10_000_000)
        let secondSaveTask = Task {
            try await store.saveImage(secondData, for: url)
        }

        _ = try await firstSaveTask.value
        let fileURL = try await secondSaveTask.value
        let savedData = try Data(contentsOf: fileURL)

        #expect(savedData == secondData)

        try await store.clearDirectory()
    }
}
