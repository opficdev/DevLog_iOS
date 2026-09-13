//
//  DevelopmentRecordEditorFeatureTests.swift
//  DevelopmentTests
//
//  Created by opfic on 9/13/26.
//

import Testing
import Domain
import PresentationShared
@testable import Development

@MainActor
struct DevelopmentRecordEditorFeatureTests {
    @Test("새 기록 저장은 초안을 생성한다")
    func 새_기록_저장은_초안을_생성한다() async throws {
        let record = try makeDevelopmentRecord()
        let version = try makeDevelopmentRecordVersion()
        let store = makeStore(createResult: .success(record), confirmResult: .success(version))
        await store.send(.binding(.set(\.title, "기록 제목"))) {
            $0.title = "기록 제목"
        }

        await store.send(.view(.save)) {
            $0.isLoading = true
        }
        await store.receive(.store(.saved(record))) {
            $0.record = record
            $0.isLoading = false
            $0.result = .saved(record)
        }
        await store.receive(.delegate(.saved(record)))
    }

    @Test("최초 확정은 새 초안을 만든 뒤 initial 버전을 생성한다")
    func 최초_확정은_새_초안을_만든_뒤_initial_버전을_생성한다() async throws {
        let record = try makeDevelopmentRecord()
        let version = try makeDevelopmentRecordVersion()
        let store = makeStore(createResult: .success(record), confirmResult: .success(version))
        await store.send(.binding(.set(\.title, "기록 제목"))) {
            $0.title = "기록 제목"
        }

        await store.send(.view(.confirm)) {
            $0.isLoading = true
        }
        await store.receive(.store(.preparedForConfirmation(record))) {
            $0.record = record
        }
        await store.receive(.store(.confirmed(version))) {
            $0.isLoading = false
            $0.result = .confirmed(version)
        }
        await store.receive(.delegate(.confirmed(version)))
    }

    @Test("확정 전 기존 초안은 입력한 내용으로 다시 저장한다")
    func 확정_전_기존_초안은_입력한_내용으로_다시_저장한다() async throws {
        let record = try makeDevelopmentRecord()
        let updatedRecord = try makeDevelopmentRecord(
            draft: makeDevelopmentRecordDraft(title: "수정한 제목")
        )
        let version = try makeDevelopmentRecordVersion()
        let store = makeStore(
            record: record,
            createResult: .failure(DevelopmentRecordTestError.failed),
            saveResult: .success(updatedRecord),
            confirmResult: .success(version)
        )
        await store.send(.binding(.set(\.title, "수정한 제목"))) {
            $0.title = "수정한 제목"
        }

        await store.send(.view(.save)) {
            $0.isLoading = true
        }
        await store.receive(.store(.saved(updatedRecord))) {
            $0.record = updatedRecord
            $0.isLoading = false
            $0.result = .saved(updatedRecord)
        }
        await store.receive(.delegate(.saved(updatedRecord)))
    }

    @Test("확정된 기록은 #871 전까지 저장과 확정을 허용하지 않는다")
    func 확정된_기록은_871_전까지_저장과_확정을_허용하지_않는다() async throws {
        let record = try makeConfirmedDevelopmentRecord()
        let version = try makeDevelopmentRecordVersion()
        let store = makeStore(
            record: record,
            createResult: .failure(DevelopmentRecordTestError.failed),
            confirmResult: .success(version)
        )

        #expect(!store.state.isReadyToSave)
        #expect(!store.state.canConfirmInitialVersion)
        await store.send(.view(.save))
        await store.send(.view(.confirm))
    }

    @Test("확정 실패 뒤 재시도는 생성된 기록을 다시 사용한다")
    func 확정_실패_뒤_재시도는_생성된_기록을_다시_사용한다() async throws {
        let record = try makeDevelopmentRecord()
        let version = try makeDevelopmentRecordVersion()
        let createSpy = CreateDevelopmentRecordUseCaseSpy(result: .success(record))
        let confirmSpy = ConfirmDevelopmentRecordUseCaseSpy(results: [
            .failure(DevelopmentRecordTestError.failed),
            .success(version)
        ])
        let store = TestStore(
            initialState: DevelopmentRecordEditorFeature.State(
                goalId: "goal",
                goalTitle: "개발 목표"
            )
        ) {
            DevelopmentRecordEditorFeature()
        } withDependencies: {
            $0.developmentCreateRecordUseCase = createSpy
            $0.developmentSaveRecordDraftUseCase = SaveDevelopmentRecordDraftUseCaseStub(
                result: .success(record)
            )
            $0.developmentConfirmRecordUseCase = confirmSpy
        }
        await store.send(.binding(.set(\.title, "기록 제목"))) {
            $0.title = "기록 제목"
        }

        await store.send(.view(.confirm)) {
            $0.isLoading = true
        }
        await store.receive(.store(.preparedForConfirmation(record))) {
            $0.record = record
        }
        await store.receive(.store(.failed)) {
            $0.isLoading = false
            $0.alert = makeDevelopmentRecordErrorAlert("development_record_editor_error_message")
        }
        await store.send(.alert(.dismiss)) {
            $0.alert = nil
        }
        await store.send(.view(.confirm)) {
            $0.isLoading = true
            $0.result = nil
        }
        await store.receive(.store(.preparedForConfirmation(record)))
        await store.receive(.store(.confirmed(version))) {
            $0.isLoading = false
            $0.result = .confirmed(version)
        }
        await store.receive(.delegate(.confirmed(version)))

        #expect(await createSpy.requests().count == 1)
        #expect(await confirmSpy.requests() == [
            .init(goalId: "goal", recordId: record.id, baseVersionId: nil),
            .init(goalId: "goal", recordId: record.id, baseVersionId: nil)
        ])
    }

    private func makeStore(
        record: DevelopmentRecord? = nil,
        createResult: Result<DevelopmentRecord, Error>,
        saveResult: Result<DevelopmentRecord, Error>? = nil,
        confirmResult: Result<DevelopmentRecord.Version, Error>
    ) -> TestStoreOf<DevelopmentRecordEditorFeature> {
        TestStore(
            initialState: DevelopmentRecordEditorFeature.State(
                goalId: "goal",
                goalTitle: "개발 목표",
                record: record
            )
        ) {
            DevelopmentRecordEditorFeature()
        } withDependencies: {
            $0.developmentCreateRecordUseCase = CreateDevelopmentRecordUseCaseStub(result: createResult)
            $0.developmentSaveRecordDraftUseCase = SaveDevelopmentRecordDraftUseCaseStub(
                result: saveResult ?? record.map { .success($0) } ?? createResult
            )
            $0.developmentConfirmRecordUseCase = ConfirmDevelopmentRecordUseCaseStub(
                result: confirmResult
            )
        }
    }
}
