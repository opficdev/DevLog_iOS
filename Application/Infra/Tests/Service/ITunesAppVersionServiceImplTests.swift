//
//  ITunesAppVersionServiceImplTests.swift
//  InfraTests
//
//  Created by opfic on 7/24/26.
//

import Foundation
import Nexa
import Testing
@testable import Infra

struct ITunesAppVersionServiceImplTests {
    @Test("Nexa 요청은 기존 쿼리를 유지하고 timestamp를 교체한다")
    func Nexa_요청은_기존_쿼리를_유지하고_timestamp를_교체한다() async throws {
        let url = try ITunesAppVersionServiceImpl.lookupURL(
            from: "https://itunes.apple.com/lookup?id=6760288611&country=KR&timestamp=1"
        )
        let client = NXAPIClient(
            configuration: NXClientConfiguration(baseURL: url)
        )
        let request = try await client
            .request(ITunesLookupEndpoint(timestamp: 1_722_000_000))
            .preparedURLRequest()
        let requestURL = try #require(request.url)
        let queryItems = try #require(
            URLComponents(
                url: requestURL,
                resolvingAgainstBaseURL: false
            )?.queryItems
        )

        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(queryItems.first { $0.name == "id" }?.value == "6760288611")
        #expect(queryItems.first { $0.name == "country" }?.value == "KR")
        #expect(
            queryItems.filter { $0.name == "timestamp" }.map(\.value) == [
                "1722000000"
            ]
        )
    }

    @Test("조회 URL이 없거나 비어 있거나 미해결 값이면 실패한다")
    func 조회_URL이_없거나_비어_있거나_미해결_값이면_실패한다() {
        let lookupURLStrings: [String?] = [
            nil,
            "",
            " \n ",
            "$(APP_STORE_LOOKUP_URL)"
        ]

        for lookupURLString in lookupURLStrings {
            #expect(throws: AppVersionServiceError.missingLookupURL) {
                try ITunesAppVersionServiceImpl.lookupURL(
                    from: lookupURLString
                )
            }
        }
    }

    @Test("잘못된 조회 URL이면 실패한다")
    func 잘못된_조회_URL이면_실패한다() {
        #expect(throws: AppVersionServiceError.invalidLookupURL) {
            try ITunesAppVersionServiceImpl.lookupURL(
                from: "itunes.apple.com/lookup?id=6760288611"
            )
        }
    }

    @Test("iTunes 응답에서 첫 버전을 추출한다")
    func iTunes_응답에서_첫_버전을_추출한다() throws {
        let data = Data(
            #"{"results":[{"version":"1.2.3"},{"version":"2.0.0"}]}"#.utf8
        )

        let response = try JSONDecoder().decode(
            ITunesLookupResponse.self,
            from: data
        )

        #expect(response.version == "1.2.3")
    }

    @Test("iTunes 결과가 비어 있으면 버전이 없다")
    func iTunes_결과가_비어_있으면_버전이_없다() throws {
        let data = Data(#"{"results":[]}"#.utf8)

        let response = try JSONDecoder().decode(
            ITunesLookupResponse.self,
            from: data
        )

        #expect(response.version == nil)
    }

    @Test("iTunes JSON 형식이 잘못되면 디코딩에 실패한다")
    func iTunes_JSON_형식이_잘못되면_디코딩에_실패한다() {
        let data = Data("invalid".utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(
                ITunesLookupResponse.self,
                from: data
            )
        }
    }

    @Test("버전 앞뒤 공백을 제거한다")
    func 버전_앞뒤_공백을_제거한다() throws {
        #expect(
            try ITunesAppVersionServiceImpl.normalizedVersion(
                " 1.2.3 \n"
            ) == "1.2.3"
        )
    }

    @Test("버전 형식이 잘못되면 실패한다", arguments: ["", "1.beta.0", "1..0"])
    func 버전_형식이_잘못되면_실패한다(version: String) {
        #expect(throws: AppVersionServiceError.invalidVersion) {
            try ITunesAppVersionServiceImpl.normalizedVersion(version)
        }
    }
}
