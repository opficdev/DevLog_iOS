//
//  WebPageRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/8/26.
//

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
        try await webPageService
            .fetchWebPages(query)
            .compactMap { try? $0.toDomain() }
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
    }
}
