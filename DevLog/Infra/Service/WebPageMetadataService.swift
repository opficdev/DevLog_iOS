//
//  WebPageMetadataService.swift
//  DevLog
//
//  Created by 최윤진 on 2/9/26.
//

import Foundation
import LinkPresentation

final class WebPageMetadataService {
    func fetchMetadata(from response: WebPageResponse) async throws -> WebPageMetadata {
        guard let url = URL(string: response.urlString) else {
            throw URLError(.badURL)
        }

        let provider = LPMetadataProvider()
        provider.timeout = 10.0

        let metadata = try await provider.startFetchingMetadata(for: url)

        let imageURL = try await extractImageURL(from: metadata.imageProvider, url: url)

        return WebPageMetadata(
            title: metadata.title,
            url: url,
            displayURL: metadata.url ?? url,
            imageURL: imageURL
        )
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
