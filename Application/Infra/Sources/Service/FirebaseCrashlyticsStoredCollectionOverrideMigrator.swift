//
//  FirebaseCrashlyticsStoredCollectionOverrideMigrator.swift
//  Infra
//
//  Created by opfic on 7/22/26.
//

import Foundation

struct FirebaseCrashlyticsOverrideMigrator {
    enum MigrationError: Error {
        case invalidStoredProperties
    }

    private enum Storage {
        static let directoryName = "com.crashlytics"
        static let fileName = "CLSUserDefaults.plist"
        static let collectionEnabledKey = "com.crashlytics.data_collection"
    }

    private let fileManager: FileManager
    private let applicationSupportDirectoryURL: URL?

    init(
        fileManager: FileManager = .default,
        applicationSupportDirectoryURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.applicationSupportDirectoryURL = applicationSupportDirectoryURL
    }

    func removeStoredOverride() throws {
        let directoryURL: URL
        if let applicationSupportDirectoryURL {
            directoryURL = applicationSupportDirectoryURL
        } else {
            directoryURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
        }

        let fileURL = directoryURL
            .appendingPathComponent(Storage.directoryName, isDirectory: true)
            .appendingPathComponent(Storage.fileName, isDirectory: false)

        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        let data = try Data(contentsOf: fileURL)
        var format = PropertyListSerialization.PropertyListFormat.xml
        guard var properties = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: &format
        ) as? [String: Any] else {
            throw MigrationError.invalidStoredProperties
        }
        guard properties.removeValue(forKey: Storage.collectionEnabledKey) != nil else { return }

        let migratedData = try PropertyListSerialization.data(
            fromPropertyList: properties,
            format: format,
            options: 0
        )
        try migratedData.write(to: fileURL, options: .atomic)
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.none],
            ofItemAtPath: fileURL.path
        )
    }
}
