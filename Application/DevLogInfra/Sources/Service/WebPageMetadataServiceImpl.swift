//
//  WebPageMetadataServiceImpl.swift
//  DevLogInfra
//
//  Created by 최윤진 on 2/9/26.
//

import Foundation
import LinkPresentation
import UIKit
import DevLogCore
import DevLogData

final class WebPageMetadataServiceImpl: WebPageMetadataService {
    private enum CrashlyticsError {
        static let domain = "DevLogInfra.WebPageMetadataServiceImpl"

        enum Code: Int {
            case fetchMetadata = 1
            case removeCachedImage
            case cachedImageURL
        }
    }

    private let imageStore: WebPageImageStore
    private let logger = Logger(category: "WebPageMetadataServiceImpl")

    init(store: WebPageImageStore) {
        self.imageStore = store
    }

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
            record(error, code: .fetchMetadata)
            throw error
        }
    }

    func removeCachedImage(for urlString: String) async {
        guard let url = URL(string: urlString) else {
            logger.error("Invalid URL for cached image removal: \(urlString)")
            return
        }

        do {
            let removed = try await imageStore.removeImage(for: url)

            if removed {
                logger.info("Removed cached image for URL: \(urlString)")
            }
        } catch {
            logger.error("Failed to remove cached image", error: error)
            record(error, code: .removeCachedImage)
        }
    }

    func cachedImageURL(for urlString: String) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        do {
            return try await imageStore.cachedImageURL(for: url)
        } catch {
            logger.error("Failed to fetch cached image URL", error: error)
            record(error, code: .cachedImageURL)
            throw error
        }
    }

    private func extractImageURL(from imageProvider: NSItemProvider?, url: URL) async throws -> URL? {
        guard let imageProvider else { return nil }

        guard let data = try await imageData(from: imageProvider) else { return nil }
        return try await imageStore.saveImage(data, for: url)
    }

    private func imageData(from imageProvider: NSItemProvider) async throws -> Data? {
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

                continuation.resume(returning: data)
            }
        }
    }
}

private extension WebPageMetadataServiceImpl {
    private static func record(_ error: Error, code: CrashlyticsError.Code) {
        FirebaseCrashlyticsHelper.record(
            error,
            domain: CrashlyticsError.domain,
            code: code.rawValue
        )
    }

    private func record(_ error: Error, code: CrashlyticsError.Code) {
        Self.record(error, code: code)
    }
}
