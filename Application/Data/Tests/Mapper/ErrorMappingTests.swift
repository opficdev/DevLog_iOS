//
//  ErrorMappingTests.swift
//  DataTests
//
//  Created by opfic on 8/28/26.
//

import Testing
import Domain
@testable import Data

struct ErrorMappingTests {
    @Test("Draft 기준 버전 충돌은 Domain 충돌 오류로 변환한다")
    func Draft_기준_버전_충돌은_Domain_충돌_오류로_변환한다() {
        let error = DataLayerError.developmentRecordDraftConflict.toDomain()

        #expect(error as? DomainLayerError == .developmentRecordDraftConflict)
    }
}
