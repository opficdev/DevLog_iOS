//
//  WebPageImageStore.swift
//  DevLog
//
//  Created by opfic on 4/14/26.
//

import CryptoKit
import Foundation

actor WebPageImageStore {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func cachedImageURL(for url: URL) throws -> URL {
        let imageDirectoryURL = try self.imageDirectoryURL(create: true)
        let fileName = hashedFileName(for: url)

        return imageDirectoryURL
            .appendingPathComponent(fileName)
            .appendingPathExtension("jpeg")
    }

    func saveImage(_ data: Data, for url: URL) throws -> URL {
        let fileURL = try cachedImageURL(for: url)
        try data.write(to: fileURL, options: [.atomic])
        return fileURL
    }

    func dirSizeInBytes() -> Int64 {
        do {
            let imageDirectoryURL = try self.imageDirectoryURL(create: false)
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
        } catch {
            return 0
        }
    }

    func clearDirectory() throws {
        let imageDirectoryURL = try self.imageDirectoryURL(create: false)
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

    func removeImage(for url: URL) throws -> Bool {
        let fileURL = try cachedImageURL(for: url)
        guard fileManager.fileExists(atPath: fileURL.path) else { return false }
        try fileManager.removeItem(at: fileURL)
        return true
    }
}

private extension WebPageImageStore {
    func hashedFileName(for url: URL) -> String {
        let hashValue = SHA256.hash(data: Data(url.absoluteString.utf8))
        return hashValue.map { String(format: "%02x", $0) }.joined()
    }

    func imageDirectoryURL(create: Bool) throws -> URL {
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
