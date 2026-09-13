//
//  DevelopmentRecordDetailFeatureTests.swift
//  DevelopmentTests
//
//  Created by opfic on 9/13/26.
//

import Testing
@testable import Development

@MainActor
struct DevelopmentRecordDetailFeatureTests {
    @Test("상세는 currentVersion과 일치하는 확정 버전을 표시한다")
    func 상세는_currentVersion과_일치하는_확정_버전을_표시한다() async throws {
        let record = try makeConfirmedDevelopmentRecord()
        let version = try makeDevelopmentRecordVersion()
        let store = TestStore(
            initialState: DevelopmentRecordDetailFeature.State(
                goalTitle: "개발 목표",
                record: record
            )
        ) {
            DevelopmentRecordDetailFeature()
        } withDependencies: {
            $0.developmentFetchRecordHistoryUseCase = FetchDevelopmentRecordHistoryUseCaseStub(
                resultByRecordId: [record.id: .success([version])]
            )
        }

        await store.send(.view(.fetch)) {
            $0.isLoading = true
        }
        await store.receive(.store(.loaded(version))) {
            $0.currentVersion = version
            $0.isLoading = false
            $0.hasLoaded = true
        }
    }

    @Test("확정 전 상세는 이력 조회 없이 초안을 유지한다")
    func 확정_전_상세는_이력_조회_없이_초안을_유지한다() async throws {
        let record = try makeDevelopmentRecord()
        let store = TestStore(
            initialState: DevelopmentRecordDetailFeature.State(
                goalTitle: "개발 목표",
                record: record
            )
        ) {
            DevelopmentRecordDetailFeature()
        }

        await store.send(.view(.fetch)) {
            $0.hasLoaded = true
        }
    }
}
