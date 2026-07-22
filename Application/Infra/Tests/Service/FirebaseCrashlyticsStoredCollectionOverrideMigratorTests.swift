//
//  FirebaseCrashlyticsStoredCollectionOverrideMigratorTests.swift
//  InfraTests
//
//  Created by opfic on 7/22/26.
//

import Foundation
import Testing
@testable import Infra

struct FirebaseCrashlyticsOverrideMigratorTests {
    private enum Storage {
        static let directoryName = "com.crashlytics"
        static let fileName = "CLSUserDefaults.plist"
        static let collectionEnabledKey = "com.crashlytics.data_collection"
    }

    @Test("저장 파일이 없으면 아무 작업도 하지 않는다")
    func 저장_파일이_없으면_아무_작업도_하지_않는다() throws {
        let directoryURL = try makeTemporaryDirectoryURL()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let migrator = FirebaseCrashlyticsOverrideMigrator(
            applicationSupportDirectoryURL: directoryURL
        )

        try migrator.removeStoredOverride()
    }

    @Test("저장된 수집 상태만 제거하고 다른 속성은 유지한다")
    func 저장된_수집_상태만_제거하고_다른_속성은_유지한다() throws {
        let directoryURL = try makeTemporaryDirectoryURL()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let fileURL = try writeStoredProperties(
            [
                Storage.collectionEnabledKey: 1,
                "preserved": "value"
            ],
            to: directoryURL
        )
        let migrator = FirebaseCrashlyticsOverrideMigrator(
            applicationSupportDirectoryURL: directoryURL
        )

        try migrator.removeStoredOverride()

        let properties = try readStoredProperties(from: fileURL)
        #expect(properties[Storage.collectionEnabledKey] == nil)
        #expect(properties["preserved"] as? String == "value")
    }

    @Test("저장된 수집 상태가 없으면 기존 속성을 유지한다")
    func 저장된_수집_상태가_없으면_기존_속성을_유지한다() throws {
        let directoryURL = try makeTemporaryDirectoryURL()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let fileURL = try writeStoredProperties(
            ["preserved": "value"],
            to: directoryURL
        )
        let migrator = FirebaseCrashlyticsOverrideMigrator(
            applicationSupportDirectoryURL: directoryURL
        )

        try migrator.removeStoredOverride()

        let properties = try readStoredProperties(from: fileURL)
        #expect(properties["preserved"] as? String == "value")
    }

    @Test("저장 파일의 최상위 값이 딕셔너리가 아니면 실패한다")
    func 저장_파일의_최상위_값이_딕셔너리가_아니면_실패한다() throws {
        let directoryURL = try makeTemporaryDirectoryURL()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let fileURL = try makeStoredPropertiesURL(in: directoryURL)
        let data = try PropertyListSerialization.data(
            fromPropertyList: ["value"],
            format: .xml,
            options: 0
        )
        try data.write(to: fileURL)
        let migrator = FirebaseCrashlyticsOverrideMigrator(
            applicationSupportDirectoryURL: directoryURL
        )

        #expect(throws: FirebaseCrashlyticsOverrideMigrator.MigrationError.self) {
            try migrator.removeStoredOverride()
        }
    }
}

private extension FirebaseCrashlyticsOverrideMigratorTests {
    func makeTemporaryDirectoryURL() throws -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        return directoryURL
    }

    func makeStoredPropertiesURL(in directoryURL: URL) throws -> URL {
        let crashlyticsDirectoryURL = directoryURL
            .appendingPathComponent(Storage.directoryName, isDirectory: true)
        try FileManager.default.createDirectory(
            at: crashlyticsDirectoryURL,
            withIntermediateDirectories: true
        )
        return crashlyticsDirectoryURL
            .appendingPathComponent(Storage.fileName, isDirectory: false)
    }

    func writeStoredProperties(
        _ properties: [String: Any],
        to directoryURL: URL
    ) throws -> URL {
        let fileURL = try makeStoredPropertiesURL(in: directoryURL)
        let data = try PropertyListSerialization.data(
            fromPropertyList: properties,
            format: .xml,
            options: 0
        )
        try data.write(to: fileURL)
        return fileURL
    }

    func readStoredProperties(from fileURL: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: fileURL)
        return try #require(
            PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any]
        )
    }
}
