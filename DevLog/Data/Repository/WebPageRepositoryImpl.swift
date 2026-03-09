//
//  WebPageRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/8/26.
//

import Foundation

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
        let responses = try await webPageService.fetchWebPages(query)
        var pages: [WebPage] = []
        pages.reserveCapacity(responses.count)

        for response in responses {
            if needsImageRestore(response), let restored = try? await restoreWebPage(response) {
                pages.append(restored)
                continue
            }
            if let page = try? response.toDomain() {
                pages.append(page)
            }
        }

        return pages
    }

    func upsert(_ urlString: String) async throws {
        let metadata = try await metadataService.fetchMetadata(from: urlString)
        let request = WebPageRequest(
            title: metadata.title,
            url: urlString,
            displayURL: metadata.displayURL,
            imageURL: metadata.imageURL
        )
        try await webPageService.upsertWebPage(request)
    }

    func delete(_ urlString: String) async throws {
        try await webPageService.deleteWebPage(urlString)
        metadataService.removeCachedImage(for: urlString)
    }
}

private extension WebPageRepositoryImpl {
    func needsImageRestore(_ response: WebPageResponse) -> Bool {
        guard !response.imageURL.isEmpty,
              let url = URL(string: response.imageURL),
              url.isFileURL else {
            return false
        }
        return !FileManager.default.fileExists(atPath: url.path)
    }

    func restoreWebPage(_ response: WebPageResponse) async throws -> WebPage? {
        let metadata = try await metadataService.fetchMetadata(from: response.url)
        let request = WebPageRequest(
            title: metadata.title,
            url: response.url,
            displayURL: metadata.displayURL,
            imageURL: metadata.imageURL
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
}
