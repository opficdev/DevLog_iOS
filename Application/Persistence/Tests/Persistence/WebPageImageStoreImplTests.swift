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
    @Test("웹페이지 이미지 캐시는 계정별로 분리되고 현재 계정 삭제는 다른 계정을 유지한다")
    func 웹페이지_이미지_캐시는_계정별로_분리되고_현재_계정_삭제는_다른_계정을_유지한다() async throws {
        let store = WebPageImageStoreImpl()
        let fileManager = FileManager.default
        let url = try #require(URL(string: "https://example.com/image"))
        let firstAccountID = "account-a"
        let secondAccountID = "account-b"

        try await store.clearDirectory(accountID: firstAccountID)
        try await store.clearDirectory(accountID: secondAccountID)

        let firstFileURL = try await store.saveImage(
            Data("first-account".utf8),
            for: url,
            accountID: firstAccountID
        )
        let secondFileURL = try await store.saveImage(
            Data("second-account".utf8),
            for: url,
            accountID: secondAccountID
        )

        #expect(firstFileURL.lastPathComponent == secondFileURL.lastPathComponent)
        #expect(firstFileURL.deletingLastPathComponent() != secondFileURL.deletingLastPathComponent())
        #expect(fileManager.fileExists(atPath: firstFileURL.path))
        #expect(fileManager.fileExists(atPath: secondFileURL.path))

        try await store.clearDirectory(accountID: firstAccountID)

        let firstDirectorySize = await store.dirSizeInBytes(accountID: firstAccountID)
        let secondDirectorySize = await store.dirSizeInBytes(accountID: secondAccountID)
        #expect(firstDirectorySize == 0)
        #expect(0 < secondDirectorySize)
        #expect(!fileManager.fileExists(atPath: firstFileURL.path))
        #expect(fileManager.fileExists(atPath: secondFileURL.path))

        try await store.clearDirectory(accountID: secondAccountID)
    }
}
