//
//  WebPageRepositoryImpl.swift
//  Data
//
//  Created by 최윤진 on 2/8/26.
//

import Foundation
import UIKit
import Domain

final class WebPageRepositoryImpl: WebPageRepository {
    private let authService: AuthService
    private let metadataService: WebPageMetadataService
    private let webPageService: WebPageService

    init(
        authService: AuthService,
        metadataService: WebPageMetadataService,
        webPageService: WebPageService
    ) {
        self.authService = authService
        self.metadataService = metadataService
        self.webPageService = webPageService
    }

    func fetch(_ query: String) async throws -> [WebPage] {
        do {
            let accountID = authService.uid
            let responses = try await webPageService.fetchWebPages(query)
            var pages: [WebPage] = []
            pages.reserveCapacity(responses.count)

            for response in responses {
                if await needsImageRestore(response, accountID: accountID) {
                    if let restored = try? await restoreWebPage(response, accountID: accountID) {
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
            let accountID = authService.uid
            let metadata = try await metadataService.fetchMetadata(from: urlString, accountID: accountID)
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
            let accountID = authService.uid
            try await webPageService.deleteWebPage(id)
            await metadataService.removeCachedImage(for: urlString, accountID: accountID)
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
    func needsImageRestore(_ response: WebPageResponse, accountID: String?) async -> Bool {
        guard !response.imageURL.isEmpty,
              let imageURL = URL(string: response.imageURL),
              imageURL.isFileURL else {
            return false
        }

        let expectedImageURL: URL
        do {
            expectedImageURL = try await metadataService.cachedImageURL(for: response.url, accountID: accountID)
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

    func restoreWebPage(_ response: WebPageResponse, accountID: String?) async throws -> WebPage? {
        let metadata = try await metadataService.fetchMetadata(from: response.url, accountID: accountID)
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
