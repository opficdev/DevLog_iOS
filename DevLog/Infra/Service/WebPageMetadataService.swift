//
//  WebPageMetadataService.swift
//  DevLog
//
//  Created by 최윤진 on 2/9/26.
//

import Foundation
import LinkPresentation
import UIKit

final class WebPageMetadataService {
    private let logger = Logger(category: "WebPageMetadataService")
    func fetchMetadata(from urlString: String) async throws -> WebPageMetadataResponse {
        logger.info("Fetching metadata for URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            logger.error("Invalid URL: \(urlString)")
            throw URLError(.badURL)
        }

        do {
            let provider = LPMetadataProvider()
            provider.timeout = 10.0

            let metadata = try await provider.startFetchingMetadata(for: url)
            let imageURL = try await extractImageURL(from: metadata.imageProvider, url: url)

            logger.info("Successfully fetched metadata for: \(metadata.title ?? "Unknown")")
            return WebPageMetadataResponse(
                title: metadata.title ?? "",
                displayURL: (metadata.url ?? url).absoluteString,
                imageURL: imageURL?.absoluteString ?? ""
            )
        } catch {
            logger.error("Failed to fetch metadata", error: error)
            throw error
        }
    }

    private func extractImageURL(from imageProvider: NSItemProvider?, url: URL) async throws -> URL? {
        guard let imageProvider else { return nil }

        return try await withCheckedThrowingContinuation { continuation in
            imageProvider.loadObject(ofClass: UIImage.self) { image, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let image = image as? UIImage,
                      let data = image.jpegData(compressionQuality: 1.0) else {
                    continuation.resume(returning: nil)
                    return
                }

                do {
                    let fileURL = try Self.cacheFileURL(for: url)
                    Task.detached { [data, fileURL] in
                        do {
                            if FileManager.default.fileExists(atPath: fileURL.path) {
                                if let existingData = try? Data(contentsOf: fileURL),
                                   UIImage(data: existingData) != nil {
                                    continuation.resume(returning: fileURL)
                                    return
                                }
                            }
                            try data.write(to: fileURL, options: [.atomic])
                            continuation.resume(returning: fileURL)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func cacheFileURL(for url: URL) throws -> URL {
        let cachesDir = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let imageDir = cachesDir.appendingPathComponent("webPageImages", isDirectory: true)
        if !FileManager.default.fileExists(atPath: imageDir.path) {
            try FileManager.default.createDirectory(at: imageDir, withIntermediateDirectories: true)
        }

        let fileName = url.absoluteString
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString

        return imageDir
            .appendingPathComponent(fileName)
            .appendingPathExtension("jpeg")
    }
}
