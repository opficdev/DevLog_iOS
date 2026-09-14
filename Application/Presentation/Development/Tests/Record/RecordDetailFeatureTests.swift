//
//  RecordDetailFeatureTests.swift
//  DevelopmentTests
//
//  Created by opfic on 9/13/26.
//

import Foundation
import Testing
import PresentationShared
@testable import Development

@MainActor
struct RecordDetailFeatureTests {
    @Test("상세는 currentVersion과 일치하는 확정 버전을 표시한다")
    func 상세는_currentVersion과_일치하는_확정_버전을_표시한다() async throws {
        let record = try makeConfirmedDevelopmentRecord()
        let version = try makeDevelopmentRecordVersion()
        let store = TestStore(
            initialState: RecordDetailFeature.State(
                goalTitle: "개발 목표",
                record: record
            )
        ) {
            RecordDetailFeature()
        } withDependencies: {
            $0.developmentFetchRecordsUseCase = FetchDevelopmentRecordsUseCaseStub(
                result: .success([record])
            )
            $0.developmentFetchRecordHistoryUseCase = FetchDevelopmentRecordHistoryUseCaseStub(
                resultByRecordId: [record.id: .success([version])]
            )
        }

        await store.send(.view(.fetch)) {
            $0.contentState = .loading
        }
        await store.receive(.store(.loaded(record, [version]))) {
            $0.versions = [version]
            $0.contentState = .loaded
        }
    }

    @Test("확정 전 상세는 이력 조회 없이 초안을 유지한다")
    func 확정_전_상세는_이력_조회_없이_초안을_유지한다() async throws {
        let record = try makeDevelopmentRecord()
        let store = TestStore(
            initialState: RecordDetailFeature.State(
                goalTitle: "개발 목표",
                record: record
            )
        ) {
            RecordDetailFeature()
        }

        let draft = try #require(record.draft)
        #expect(store.state.contentState == .draft(draft))
        await store.send(.view(.fetch))
    }

    @Test("확정 기록 조회 실패는 초안 대신 재시도 상태를 표시한다")
    func 확정_기록_조회_실패는_초안_대신_재시도_상태를_표시한다() async throws {
        let record = try makeConfirmedDevelopmentRecord()
        let store = TestStore(
            initialState: RecordDetailFeature.State(
                goalTitle: "개발 목표",
                record: record
            )
        ) {
            RecordDetailFeature()
        } withDependencies: {
            $0.developmentFetchRecordsUseCase = FetchDevelopmentRecordsUseCaseStub(
                result: .success([record])
            )
            $0.developmentFetchRecordHistoryUseCase = FetchDevelopmentRecordHistoryUseCaseStub(
                resultByRecordId: [record.id: .failure(RecordTestError.failed)]
            )
        }

        await store.send(.view(.fetch)) {
            $0.contentState = .loading
        }
        await store.receive(.store(.loadFailed)) {
            $0.contentState = .failed
            $0.alert = makeRecordErrorAlert("development_record_detail_error_message")
        }
        await store.send(.alert(.dismiss)) {
            $0.alert = nil
        }
        await store.send(.view(.fetch)) {
            $0.contentState = .loading
        }
        await store.receive(.store(.loadFailed)) {
            $0.contentState = .failed
            $0.alert = makeRecordErrorAlert("development_record_detail_error_message")
        }
    }

    @Test("이전 버전 되돌리기는 새 버전을 현재 버전으로 반영한다")
    func 이전_버전_되돌리기는_새_버전을_현재_버전으로_반영한다() async throws {
        let restoreVersionID = "00000000-0000-0000-0000-000000000003"
        let restoreUUID = try #require(UUID(uuidString: restoreVersionID))
        let initialVersion = try makeDevelopmentRecordVersion(id: "version-1")
        let currentVersion = try makeDevelopmentRecordVersion(
            id: "version-2",
            number: 2,
            kind: .correction,
            sourceVersionId: initialVersion.id
        )
        let restoredVersion = try makeDevelopmentRecordVersion(
            id: restoreVersionID,
            number: 3,
            kind: .rollback,
            sourceVersionId: initialVersion.id
        )
        let record = try makeConfirmedDevelopmentRecord(
            versionId: currentVersion.id,
            versionNumber: currentVersion.number
        )
        let spy = RestoreDevelopmentRecordUseCaseSpy(result: .success(restoredVersion))
        var state = RecordDetailFeature.State(goalTitle: "개발 목표", record: record)
        state.versions = [initialVersion, currentVersion]
        state.contentState = .loaded
        let store = TestStore(initialState: state) {
            RecordDetailFeature()
        } withDependencies: {
            $0.developmentRestoreRecordUseCase = spy
            $0.uuid = .constant(restoreUUID)
        }

        await store.send(.view(.restore(initialVersion))) {
            $0.isRestoring = true
            $0.restoreRequest = .init(
                versionID: restoreVersionID,
                sourceVersionID: initialVersion.id
            )
        }
        await store.receive(.store(.restored(restoredVersion))) {
            $0.versions = [initialVersion, currentVersion, restoredVersion]
            $0.currentVersionID = restoredVersion.id
            $0.isRestoring = false
            $0.restoreRequest = nil
            $0.restoredSourceVersionID = initialVersion.id
        }

        #expect(await spy.requests() == [
            .init(
                goalId: record.goalId,
                recordId: record.id,
                versionId: restoreVersionID,
                sourceVersionId: initialVersion.id
            )
        ])
    }

    @Test("되돌리기 실패 재시도는 같은 버전 ID를 사용한다")
    func 되돌리기_실패_재시도는_같은_버전_ID를_사용한다() async throws {
        let restoreVersionID = "00000000-0000-0000-0000-000000000003"
        let restoreUUID = try #require(UUID(uuidString: restoreVersionID))
        let initialVersion = try makeDevelopmentRecordVersion(id: "version-1")
        let currentVersion = try makeDevelopmentRecordVersion(
            id: "version-2",
            number: 2,
            kind: .correction,
            sourceVersionId: initialVersion.id
        )
        let record = try makeConfirmedDevelopmentRecord(
            versionId: currentVersion.id,
            versionNumber: currentVersion.number
        )
        let restoredVersion = try makeDevelopmentRecordVersion(
            id: restoreVersionID,
            number: 3,
            kind: .rollback,
            sourceVersionId: initialVersion.id
        )
        let spy = RestoreDevelopmentRecordUseCaseSpy(
            results: [
                .failure(RecordTestError.failed),
                .success(restoredVersion)
            ]
        )
        var state = RecordDetailFeature.State(goalTitle: "개발 목표", record: record)
        state.versions = [initialVersion, currentVersion]
        state.contentState = .loaded
        let store = TestStore(initialState: state) {
            RecordDetailFeature()
        } withDependencies: {
            $0.developmentRestoreRecordUseCase = spy
            $0.uuid = .constant(restoreUUID)
        }

        await store.send(.view(.restore(initialVersion))) {
            $0.isRestoring = true
            $0.restoreRequest = .init(
                versionID: restoreVersionID,
                sourceVersionID: initialVersion.id
            )
        }
        await store.receive(.store(.restoreFailed)) {
            $0.isRestoring = false
            $0.alert = makeRecordErrorAlert("development_record_restore_error_message")
        }
        await store.send(.alert(.dismiss)) {
            $0.alert = nil
        }
        await store.send(.view(.restore(initialVersion))) {
            $0.isRestoring = true
        }
        await store.receive(.store(.restored(restoredVersion))) {
            $0.versions = [initialVersion, currentVersion, restoredVersion]
            $0.currentVersionID = restoredVersion.id
            $0.isRestoring = false
            $0.restoreRequest = nil
            $0.restoredSourceVersionID = initialVersion.id
        }

        #expect(await spy.requests() == [
            .init(
                goalId: record.goalId,
                recordId: record.id,
                versionId: restoreVersionID,
                sourceVersionId: initialVersion.id
            ),
            .init(
                goalId: record.goalId,
                recordId: record.id,
                versionId: restoreVersionID,
                sourceVersionId: initialVersion.id
            )
        ])
    }

    @Test("정정 초안이 있으면 이전 버전 되돌리기를 시작하지 않는다")
    func 정정_초안이_있으면_이전_버전_되돌리기를_시작하지_않는다() async throws {
        let initialVersion = try makeDevelopmentRecordVersion(id: "version-1")
        let currentVersion = try makeDevelopmentRecordVersion(
            id: "version-2",
            number: 2,
            kind: .correction,
            sourceVersionId: initialVersion.id
        )
        let record = try makeConfirmedDevelopmentRecord(
            versionId: currentVersion.id,
            versionNumber: currentVersion.number,
            draft: makeDevelopmentRecordDraft(baseVersionId: currentVersion.id)
        )
        var state = RecordDetailFeature.State(goalTitle: "개발 목표", record: record)
        state.versions = [initialVersion, currentVersion]
        state.contentState = .loaded
        let store = TestStore(initialState: state) {
            RecordDetailFeature()
        }

        await store.send(.view(.restore(initialVersion)))
    }
}
