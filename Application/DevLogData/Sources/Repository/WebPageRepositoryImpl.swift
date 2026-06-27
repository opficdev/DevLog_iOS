//
//  WebPageRepositoryImpl.swift
//  DevLogData
//
//  Created by 최윤진 on 2/8/26.
//

import Foundation
import UIKit
import DevLogDomain

final class WebPageRepositoryImpl: WebPageRepository {
    private let webPageService: WebPageService
    private let metadataService: WebPageMetadataService

    init(
        webPageService: WebPageService,
        metadataService: WebPageMetadataService
    ) {
        self.webPageService = webPageService
        self.metadataService = metadataService
    }

    func fetch(_ query: String) async throws -> [WebPage] {
        do {
            let responses = try await webPageService.fetchWebPages(query)
            var pages: [WebPage] = []
            pages.reserveCapacity(responses.count)

            for response in responses {
                if await needsImageRestore(response) {
                    if let restored = try? await restoreWebPage(response) {
                        pages.append(restored)
                    } else if let page = try? responseWithoutImage(response).toDomain() {
                        pages.append(page)
                    }
                    continue
                }
                if let page = try? response.toDomain() {
                    pages.append(page)
                }
            }

            return pages
        } catch {
            throw error.toDomain()
        }
    }

    func upsert(_ urlString: String) async throws {
        do {
            let metadata = try await metadataService.fetchMetadata(from: urlString)
            let request = WebPageRequest(
                title: metadata.title,
                url: urlString,
                displayURL: metadata.displayURL,
                imageURL: metadata.imageURL,
                isDeleted: false
            )
            try await webPageService.upsertWebPage(request)
        } catch {
            throw error.toDomain()
        }
    }

    func delete(id: String, urlString: String) async throws {
        do {
            try await webPageService.deleteWebPage(id)
            await metadataService.removeCachedImage(for: urlString)
        } catch {
            throw error.toDomain()
        }
    }

    func undoDelete(_ id: String) async throws {
        do {
            try await webPageService.undoDeleteWebPage(id)
        } catch {
            throw error.toDomain()
        }
    }
}

private extension WebPageRepositoryImpl {
    func needsImageRestore(_ response: WebPageResponse) async -> Bool {
        guard !response.imageURL.isEmpty,
              let imageURL = URL(string: response.imageURL),
              imageURL.isFileURL else {
            return false
        }

        let expectedImageURL: URL
        do {
            expectedImageURL = try await metadataService.cachedImageURL(for: response.url)
        } catch {
            return true
        }

        if imageURL.standardizedFileURL != expectedImageURL.standardizedFileURL {
            return true
        }

        return await Task.detached(priority: .utility) {
            guard FileManager.default.fileExists(atPath: imageURL.path) else {
                return true
            }

            guard let imageData = try? Data(contentsOf: imageURL) else {
                return true
            }

            return UIImage(data: imageData) == nil
        }.value
    }

    func restoreWebPage(_ response: WebPageResponse) async throws -> WebPage? {
        let metadata = try await metadataService.fetchMetadata(from: response.url)
        let request = WebPageRequest(
            title: metadata.title,
            url: response.url,
            displayURL: metadata.displayURL,
            imageURL: metadata.imageURL,
            isDeleted: false
        )
        try await webPageService.upsertWebPage(request)

        let newResponse = WebPageResponse(
            id: response.id,
            title: metadata.title,
            url: response.url,
            displayURL: metadata.displayURL,
            imageURL: metadata.imageURL
        )

        return try? newResponse.toDomain()
    }

    func responseWithoutImage(_ response: WebPageResponse) -> WebPageResponse {
        WebPageResponse(
            id: response.id,
            title: response.title,
            url: response.url,
            displayURL: response.displayURL,
            imageURL: ""
        )
    }
}
