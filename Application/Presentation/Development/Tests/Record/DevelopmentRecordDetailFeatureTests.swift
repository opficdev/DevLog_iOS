//
//  DevelopmentRecordDetailFeatureTests.swift
//  DevelopmentTests
//
//  Created by opfic on 9/13/26.
//

import Testing
import PresentationShared
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
            $0.contentState = .loading
        }
        await store.receive(.store(.loaded(version))) {
            $0.contentState = .confirmed(version)
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

        let draft = try #require(record.draft)
        #expect(store.state.contentState == .draft(draft))
        await store.send(.view(.fetch))
    }

    @Test("확정 기록 조회 실패는 초안 대신 재시도 상태를 표시한다")
    func 확정_기록_조회_실패는_초안_대신_재시도_상태를_표시한다() async throws {
        let record = try makeConfirmedDevelopmentRecord()
        let store = TestStore(
            initialState: DevelopmentRecordDetailFeature.State(
                goalTitle: "개발 목표",
                record: record
            )
        ) {
            DevelopmentRecordDetailFeature()
        } withDependencies: {
            $0.developmentFetchRecordHistoryUseCase = FetchDevelopmentRecordHistoryUseCaseStub(
                resultByRecordId: [record.id: .failure(DevelopmentRecordTestError.failed)]
            )
        }

        await store.send(.view(.fetch)) {
            $0.contentState = .loading
        }
        await store.receive(.store(.failed)) {
            $0.contentState = .failed
            $0.alert = DevelopmentRecordDetailFeature.errorAlert
        }
        await store.send(.alert(.dismiss)) {
            $0.alert = nil
        }
        await store.send(.view(.fetch)) {
            $0.contentState = .loading
        }
        await store.receive(.store(.failed)) {
            $0.contentState = .failed
            $0.alert = DevelopmentRecordDetailFeature.errorAlert
        }
    }
}
