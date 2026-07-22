//
//  AppVersionTests.swift
//  DomainTests
//
//  Created by opfic on 7/22/26.
//

import Testing
@testable import Domain

struct AppVersionTests {
    @Test("마케팅 버전 형식이 잘못되면 invalidData 오류를 반환한다")
    func 마케팅_버전_형식이_잘못되면_invalidData_오류를_반환한다() {
        #expect(throws: DomainLayerError.self) {
            try AppVersion(marketingVersion: "1..5", buildNumber: "127")
        }
    }

    @Test("빌드 번호 형식이 잘못되면 invalidData 오류를 반환한다")
    func 빌드_번호_형식이_잘못되면_invalidData_오류를_반환한다() {
        #expect(throws: DomainLayerError.self) {
            try AppVersion(marketingVersion: "1.5", buildNumber: "127a")
        }
    }
}
