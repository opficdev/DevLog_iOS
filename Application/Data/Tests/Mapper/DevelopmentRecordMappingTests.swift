//
//  DevelopmentRecordMappingTests.swift
//  DataTests
//
//  Created by opfic on 8/28/26.
//

import Foundation
import Testing
import Domain
@testable import Data

struct DevelopmentRecordMappingTests {
    @Test("기록 초안은 저장 요청에서 갱신 시각을 제외한다")
    func 기록_초안은_저장_요청에서_갱신_시각을_제외한다() throws {
        let draft = try DevelopmentRecord.Draft(
            title: "기록",
            markdownContent: "본문",
            baseVersionId: "version-1",
            updatedAt: .distantPast
        )

        let request = DevelopmentRecordDraftRequest.fromDomain(draft)

        #expect(request.title == "기록")
        #expect(request.markdownContent == "본문")
        #expect(request.baseVersionId == "version-1")
    }

    @Test("저장 버전 종류는 Domain 종류로 변환한다")
    func 저장_버전_종류는_Domain_종류로_변환한다() throws {
        let response = DevelopmentRecordVersionResponse(
            id: "version-1",
            recordId: "record-1",
            number: 1,
            title: "기록",
            markdownContent: "본문",
            kind: "initial",
            sourceVersionId: nil,
            confirmedAt: .distantPast
        )

        let version = try response.toDomain()

        #expect(version.kind == .initial)
        #expect(version.sourceVersionId == nil)
    }

    @Test("알 수 없는 저장 버전 종류는 유효하지 않은 데이터 오류를 만든다")
    func 알_수_없는_저장_버전_종류는_유효하지_않은_데이터_오류를_만든다() {
        #expect(throws: DataLayerError.self) {
            _ = try DevelopmentRecord.Version.Kind.fromStorageValue("unknown")
        }
    }
}
