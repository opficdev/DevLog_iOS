//
//  WebPageRepositoryImplTests.swift
//  DataTests
//
//  Created by opfic on 7/8/26.
//

import Combine
import Foundation
import Testing
import Domain
@testable import Data

struct WebPageRepositoryImplTests {
    @Test("웹페이지 저장은 현재 계정 scope로 메타데이터 캐시를 생성한다")
    func 웹페이지_저장은_현재_계정_scope로_메타데이터_캐시를_생성한다() async throws {
        let expectedImageURL = URL(fileURLWithPath: "/account-a/webPageImages/image.jpeg")
        let fixture = makeFixture(
            uid: "account-a",
            expectedImageURL: expectedImageURL
        )
        let urlString = "https://example.com/article"

        try await fixture.repository.upsert(urlString)

        #expect(await fixture.metadataService.fetchMetadataRequests() == [
            WebPageMetadataServiceRequest(urlString: urlString, accountID: "account-a")
        ])
        let requests = await fixture.webPageService.upsertedRequests()
        let request = try #require(requests.first)
        #expect(requests.count == 1)
        #expect(request.title == "metadata-title")
        #expect(request.url == urlString)
        #expect(request.displayURL == urlString)
        #expect(request.imageURL == expectedImageURL.absoluteString)
        #expect(request.isDeleted == false)
    }

    @Test("웹페이지 삭제는 현재 계정 scope의 캐시만 제거한다")
    func 웹페이지_삭제는_현재_계정_scope의_캐시만_제거한다() async throws {
        let fixture = makeFixture(uid: "account-a")
        let urlString = "https://example.com/article"

        try await fixture.repository.delete(id: "web-page-id", urlString: urlString)

        #expect(await fixture.webPageService.deletedIDs() == ["web-page-id"])
        #expect(await fixture.metadataService.removeCachedImageRequests() == [
            WebPageMetadataServiceRequest(urlString: urlString, accountID: "account-a")
        ])
    }

    @Test("현재 계정 scope와 다른 파일 캐시는 재사용하지 않고 복구한다")
    func 현재_계정_scope와_다른_파일_캐시는_재사용하지_않고_복구한다() async throws {
        let expectedImageURL = URL(fileURLWithPath: "/account-a/webPageImages/image.jpeg")
        let legacyImageURL = URL(fileURLWithPath: "/legacy/webPageImages/image.jpeg")
        let urlString = "https://example.com/article"
        let response = WebPageResponse(
            id: "web-page-id",
            title: "legacy-title",
            url: urlString,
            displayURL: urlString,
            imageURL: legacyImageURL.absoluteString
        )
        let fixture = makeFixture(
            uid: "account-a",
            responses: [response],
            expectedImageURL: expectedImageURL
        )

        let pages = try await fixture.repository.fetch("")

        #expect(await fixture.metadataService.cachedImageURLRequests() == [
            WebPageMetadataServiceRequest(urlString: urlString, accountID: "account-a")
        ])
        #expect(await fixture.metadataService.fetchMetadataRequests() == [
            WebPageMetadataServiceRequest(urlString: urlString, accountID: "account-a")
        ])
        let requests = await fixture.webPageService.upsertedRequests()
        let request = try #require(requests.first)
        let page = try #require(pages.first)
        #expect(requests.count == 1)
        #expect(request.title == "metadata-title")
        #expect(request.url == urlString)
        #expect(request.displayURL == urlString)
        #expect(request.imageURL == expectedImageURL.absoluteString)
        #expect(page.imageURL == expectedImageURL)
    }

    private func makeFixture(
        uid: String?,
        responses: [WebPageResponse] = [],
        expectedImageURL: URL = URL(fileURLWithPath: "/account/webPageImages/image.jpeg")
    ) -> WebPageRepositoryFixture {
        let authService = WebPageRepositoryAuthServiceSpy(uid: uid)
        let metadataService = WebPageMetadataServiceSpy(
            response: WebPageMetadataResponse(
                title: "metadata-title",
                displayURL: "https://example.com/article",
                imageURL: expectedImageURL.absoluteString
            ),
            expectedImageURL: expectedImageURL
        )
        let webPageService = WebPageServiceSpy(responses: responses)
        let repository = WebPageRepositoryImpl(
            authService: authService,
            metadataService: metadataService,
            webPageService: webPageService
        )

        return WebPageRepositoryFixture(
            metadataService: metadataService,
            repository: repository,
            webPageService: webPageService
        )
    }
}

private struct WebPageRepositoryFixture {
    let metadataService: WebPageMetadataServiceSpy
    let repository: WebPageRepositoryImpl
    let webPageService: WebPageServiceSpy
}

private struct WebPageMetadataServiceRequest: Equatable {
    let urlString: String
    let accountID: String?
}

private final class WebPageRepositoryAuthServiceSpy: AuthService {
    private let subject: CurrentValueSubject<Bool, Never>

    var uid: String?
    var providerIDs: [String] { [] }
    var providerCount: Int { 0 }

    init(uid: String?) {
        self.uid = uid
        self.subject = CurrentValueSubject<Bool, Never>(uid != nil)
    }

    func observeSignedIn() -> AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    func beginSignIn() { }
    func completeSignIn() { }
    func cancelSignIn() { }
    func getProviderID() async throws -> String? { nil }
    func deleteCurrentUser() async throws { }
    func clearCurrentSession() async throws { }
}

private actor WebPageMetadataServiceSpy: WebPageMetadataService {
    private let expectedImageURL: URL
    private let response: WebPageMetadataResponse
    private var cachedImageURLEvents = [WebPageMetadataServiceRequest]()
    private var fetchMetadataEvents = [WebPageMetadataServiceRequest]()
    private var removeCachedImageEvents = [WebPageMetadataServiceRequest]()

    init(
        response: WebPageMetadataResponse,
        expectedImageURL: URL
    ) {
        self.expectedImageURL = expectedImageURL
        self.response = response
    }

    func fetchMetadata(from urlString: String, accountID: String?) async throws -> WebPageMetadataResponse {
        fetchMetadataEvents.append(WebPageMetadataServiceRequest(urlString: urlString, accountID: accountID))
        return response
    }

    func removeCachedImage(for urlString: String, accountID: String?) async {
        removeCachedImageEvents.append(WebPageMetadataServiceRequest(urlString: urlString, accountID: accountID))
    }

    func cachedImageURL(for urlString: String, accountID: String?) async throws -> URL {
        cachedImageURLEvents.append(WebPageMetadataServiceRequest(urlString: urlString, accountID: accountID))
        return expectedImageURL
    }

    func cachedImageURLRequests() -> [WebPageMetadataServiceRequest] {
        cachedImageURLEvents
    }

    func fetchMetadataRequests() -> [WebPageMetadataServiceRequest] {
        fetchMetadataEvents
    }

    func removeCachedImageRequests() -> [WebPageMetadataServiceRequest] {
        removeCachedImageEvents
    }
}

private actor WebPageServiceSpy: WebPageService {
    private let responses: [WebPageResponse]
    private var deleted = [String]()
    private var upserted = [WebPageRequest]()

    init(responses: [WebPageResponse] = []) {
        self.responses = responses
    }

    func fetchWebPages(_ query: String) async throws -> [WebPageResponse] {
        responses
    }

    func upsertWebPage(_ request: WebPageRequest) async throws {
        upserted.append(request)
    }

    func deleteWebPage(_ id: String) async throws {
        deleted.append(id)
    }

    func undoDeleteWebPage(_ id: String) async throws { }

    func deletedIDs() -> [String] {
        deleted
    }

    func upsertedRequests() -> [WebPageRequest] {
        upserted
    }
}
