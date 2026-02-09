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
        let indexedResponses = responses.enumerated().map { ($0.offset, $0.element) }

        return try await withThrowingTaskGroup(of: (Int, WebPageMetadata?).self) { group in
            for (index, response) in indexedResponses {
                group.addTask {
                    let metadata = try? await self.metadataService.fetchMetadata(from: response)
                    return (index, metadata)
                }
            }

            var results: [WebPageMetadata?] = Array(repeating: nil, count: responses.count)
            for try await (index, metadata) in group {
                results[index] = metadata
            }

            return results.compactMap { $0 }
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
