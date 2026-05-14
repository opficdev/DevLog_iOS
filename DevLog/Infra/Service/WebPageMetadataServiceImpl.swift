//
//  WebPageMetadataServiceImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/9/26.
//

import Foundation
import LinkPresentation
import UIKit

final class WebPageMetadataServiceImpl: WebPageMetadataService {
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
        }
    }

    func cachedImageURL(for urlString: String) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        return try await imageStore.cachedImageURL(for: url)
    }

    private func extractImageURL(from imageProvider: NSItemProvider?, url: URL) async throws -> URL? {
        guard let imageProvider else { return nil }

        return try await withCheckedThrowingContinuation { continuation in
            //  `[imageStore]`은 배열이 아니고 캡쳐 리스트
            //  명시적으로 imageStore을 캡쳐하겠다고 작성한 것
            imageProvider.loadObject(ofClass: UIImage.self) { [imageStore] image, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let image = image as? UIImage,
                      let data = image.jpegData(compressionQuality: 1.0) else {
                    continuation.resume(returning: nil)
                    return
                }

                Task {
                    do {
                        let fileURL = try await imageStore.saveImage(data, for: url)
                        continuation.resume(returning: fileURL)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
