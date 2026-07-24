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
            try AppVersion("1..5")
        }
    }

    @Test("낮은 마케팅 버전은 높은 마케팅 버전보다 작다")
    func 낮은_마케팅_버전은_높은_마케팅_버전보다_작다() throws {
        let lowerVersion = try AppVersion("1.4.9")
        let higherVersion = try AppVersion("1.5.0")

        #expect(lowerVersion < higherVersion)
    }

    @Test("같은 마케팅 버전은 서로 작지 않다")
    func 같은_마케팅_버전은_서로_작지_않다() throws {
        let version = try AppVersion("1.5.0")
        let sameVersion = try AppVersion("1.5.0")

        #expect(!(version < sameVersion))
        #expect(!(sameVersion < version))
    }

    @Test("높은 마케팅 버전은 낮은 마케팅 버전보다 작지 않다")
    func 높은_마케팅_버전은_낮은_마케팅_버전보다_작지_않다() throws {
        let higherVersion = try AppVersion("1.5.1")
        let lowerVersion = try AppVersion("1.5.0")

        #expect(!(higherVersion < lowerVersion))
    }

    @Test("생략된 마케팅 버전 구성 요소는 0으로 비교한다")
    func 생략된_마케팅_버전_구성_요소는_0으로_비교한다() throws {
        let version = try AppVersion("1.5")
        let expandedVersion = try AppVersion("1.5.0")

        #expect(!(version < expandedVersion))
        #expect(!(expandedVersion < version))
    }
}
