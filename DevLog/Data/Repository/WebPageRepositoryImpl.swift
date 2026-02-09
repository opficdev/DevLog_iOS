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

    func fetch() async throws -> [WebPageMetadata] {
        let responses = try await webPageService.fetchWebPages()

        return try await withThrowingTaskGroup(of: WebPageMetadata?.self) { group in
            for response in responses {
                group.addTask {
                    try? await self.metadataService.fetchMetadata(from: response)
                }
            }

            var results: [WebPageMetadata] = []
            for try await metadata in group {
                if let metadata {
                    results.append(metadata)
                }
            }

            return results
        }
    }

    func upsert(_ urlString: String) async throws -> WebPageMetadata {
        try await webPageService.upsertWebPage(urlString)
        let response = WebPageResponse(urlString: urlString)
        return try await metadataService.fetchMetadata(from: response)
    }

    func delete(_ urlString: String) async throws {
        try await webPageService.deleteWebPage(urlString)
    }
}
