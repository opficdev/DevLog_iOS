//
//  FirebaseConfigurationTests.swift
//  InfraTests
//
//  Created by opfic on 7/20/26.
//

import Foundation
import Testing
@testable import Infra

struct FirebaseConfigurationTests {
    @Test("환경 변수의 database ID를 우선 사용한다")
    func 환경_변수의_database_ID를_우선_사용한다() throws {
        let databaseID = try FirebaseConfiguration.resolveDatabaseID(
            environmentValue: "prod",
            bundleValue: "staging"
        )

        #expect(databaseID == "prod")
    }

    @Test("환경 변수의 database ID가 비어 있으면 bundle 값을 사용한다")
    func 환경_변수의_database_ID가_비어_있으면_bundle_값을_사용한다() throws {
        let databaseID = try FirebaseConfiguration.resolveDatabaseID(
            environmentValue: "   ",
            bundleValue: "prod"
        )

        #expect(databaseID == "prod")
    }

    @Test("database ID가 누락되면 오류를 반환한다")
    func database_ID가_누락되면_오류를_반환한다() {
        #expect(
            throws: FirebaseConfigurationError.unresolvedValue("FIRESTORE_DATABASE_ID")
        ) {
            try FirebaseConfiguration.resolveDatabaseID(
                environmentValue: nil,
                bundleValue: nil
            )
        }
    }

    @Test("database ID가 미치환 값이면 오류를 반환한다")
    func database_ID가_미치환_값이면_오류를_반환한다() {
        #expect(
            throws: FirebaseConfigurationError.unresolvedValue("FIRESTORE_DATABASE_ID")
        ) {
            try FirebaseConfiguration.resolveDatabaseID(
                environmentValue: nil,
                bundleValue: "$(FIRESTORE_DATABASE_ID)"
            )
        }
    }

    @Test("절대 HTTPS Functions URL을 반환한다")
    func 절대_HTTPS_Functions_URL을_반환한다() throws {
        let url = try FirebaseConfiguration.resolveFunctionAPIBaseURL(
            environmentValue: nil,
            bundleValue: "https://example.com/stagingApi/api"
        )

        #expect(url == URL(string: "https://example.com/stagingApi/api"))
    }

    @Test("Functions URL이 누락되면 bad URL 오류를 반환한다")
    func Functions_URL이_누락되면_bad_URL_오류를_반환한다() {
        #expect(throws: URLError.self) {
            try FirebaseConfiguration.resolveFunctionAPIBaseURL(
                environmentValue: nil,
                bundleValue: nil
            )
        }
    }

    @Test("Functions URL이 상대 경로이면 bad URL 오류를 반환한다")
    func Functions_URL이_상대_경로이면_bad_URL_오류를_반환한다() {
        #expect(throws: URLError.self) {
            try FirebaseConfiguration.resolveFunctionAPIBaseURL(
                environmentValue: nil,
                bundleValue: "stagingApi/api"
            )
        }
    }
}
