//
//  WebPageImageStoreImpl.swift
//  DevLog
//
//  Created by opfic on 4/14/26.
//

import CryptoKit
import Foundation
import DevLogDomain
import DevLogData
import DevLogWidgetCore
import DevLogWidgetShared

actor WebPageImageStoreImpl: WebPageImageStore {
    func cachedImageURL(for url: URL) async throws -> URL {
        return try await Task.detached(priority: .utility) {
            return try Self.cachedImageURL(for: url)
        }.value
    }

    func saveImage(_ data: Data, for url: URL) async throws -> URL {
        return try await Task.detached(priority: .utility) {
            return try Self.saveImage(data, for: url)
        }.value
    }

    func dirSizeInBytes() async -> Int64 {
        do {
            return try await Task.detached(priority: .utility) {
                return try Self.dirSizeInBytes()
            }.value
        } catch {
            return 0
        }
    }

    func clearDirectory() async throws {
        try await Task.detached(priority: .utility) {
            try Self.clearDirectory()
        }.value
    }

    func removeImage(for url: URL) async throws -> Bool {
        return try await Task.detached(priority: .utility) {
            return try Self.removeImage(for: url)
        }.value
    }
}

private extension WebPageImageStoreImpl {
    static func hashedFileName(for url: URL) -> String {
        let hashValue = SHA256.hash(data: Data(url.absoluteString.utf8))
        return hashValue.map { String(format: "%02x", $0) }.joined()
    }

    static func cachedImageURL(for url: URL) throws -> URL {
        let fileManager = FileManager.default
        let imageDirectoryURL = try imageDirectoryURL(create: true, fileManager: fileManager)
        let fileName = hashedFileName(for: url)

        return imageDirectoryURL
            .appendingPathComponent(fileName)
            .appendingPathExtension("jpeg")
    }

    static func saveImage(_ data: Data, for url: URL) throws -> URL {
        let fileURL = try cachedImageURL(for: url)
        try data.write(to: fileURL, options: [.atomic])
        return fileURL
    }

    static func dirSizeInBytes() throws -> Int64 {
        let fileManager = FileManager.default
        let imageDirectoryURL = try imageDirectoryURL(create: false, fileManager: fileManager)
        guard fileManager.fileExists(atPath: imageDirectoryURL.path) else { return 0 }
        guard let enumerator = fileManager.enumerator(
            at: imageDirectoryURL,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  resourceValues.isRegularFile == true,
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            total += Int64(fileSize)
        }
        return total
    }

    static func clearDirectory() throws {
        let fileManager = FileManager.default
        let imageDirectoryURL = try imageDirectoryURL(create: false, fileManager: fileManager)
        guard fileManager.fileExists(atPath: imageDirectoryURL.path) else { return }
        let contentURLs = try fileManager.contentsOfDirectory(
            at: imageDirectoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        for contentURL in contentURLs {
            try fileManager.removeItem(at: contentURL)
        }
    }

    static func removeImage(for url: URL) throws -> Bool {
        let fileManager = FileManager.default
        let fileURL = try cachedImageURL(for: url)
        guard fileManager.fileExists(atPath: fileURL.path) else { return false }
        try fileManager.removeItem(at: fileURL)
        return true
    }

    static func imageDirectoryURL(create: Bool, fileManager: FileManager) throws -> URL {
        let directory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: create
        )
        let imageDirectory = directory.appendingPathComponent("webPageImages", isDirectory: true)
        if create && !fileManager.fileExists(atPath: imageDirectory.path) {
            try fileManager.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
        }
        if create {
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            var imageDirectory = imageDirectory
            try imageDirectory.setResourceValues(resourceValues)
        }

        return imageDirectory
    }
}
