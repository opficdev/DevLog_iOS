//
//  WebPageMetadataService.swift
//  DevLog
//
//  Created by 최윤진 on 2/9/26.
//

import Foundation
import LinkPresentation

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
                guard let image = image as? UIImage,
                      let data = image.jpegData(compressionQuality: 1.0) else {
                    continuation.resume(returning: nil)
                    return
                }

                guard let fileName = url.absoluteString.addingPercentEncoding(
                    withAllowedCharacters: .alphanumerics
                ) else {
                    continuation.resume(returning: nil)
                    return
                }

                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(fileName)
                    .appendingPathExtension("jpeg")

                do {
                    try data.write(to: tempURL)
                    continuation.resume(returning: tempURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
