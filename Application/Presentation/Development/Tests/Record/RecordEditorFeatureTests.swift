//
//  RecordEditorFeatureTests.swift
//  DevelopmentTests
//
//  Created by opfic on 9/13/26.
//

import Testing
import Domain
import PresentationShared
@testable import Development

@MainActor
struct RecordEditorFeatureTests {
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
            $0.confirmationPreparation = .init(
                record: record,
                title: "기록 제목",
                markdownContent: ""
            )
        }
        await store.receive(.store(.confirmed(version))) {
            $0.isLoading = false
            $0.result = .confirmed(version)
            $0.confirmationPreparation = nil
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
            createResult: .failure(RecordTestError.failed),
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

    @Test("확정된 기록은 현재 내용을 바탕으로 correction 버전을 만든다")
    func 확정된_기록은_현재_내용을_바탕으로_correction_버전을_만든다() async throws {
        let baseVersion = try makeDevelopmentRecordVersion(id: "version-1")
        let record = try makeConfirmedDevelopmentRecord(versionId: baseVersion.id)
        let preparedRecord = try makeConfirmedDevelopmentRecord(
            versionId: baseVersion.id,
            draft: makeDevelopmentRecordDraft(baseVersionId: baseVersion.id)
        )
        let version = try makeDevelopmentRecordVersion(
            id: "version-2",
            number: 2,
            kind: .correction,
            sourceVersionId: baseVersion.id
        )
        let spy = ConfirmDevelopmentRecordUseCaseSpy(results: [.success(version)])
        let store = TestStore(
            initialState: RecordEditorFeature.State(
                goalId: "goal",
                goalTitle: "개발 목표",
                record: record,
                baseVersion: baseVersion,
                versionId: version.id
            )
        ) {
            RecordEditorFeature()
        } withDependencies: {
            $0.developmentSaveRecordDraftUseCase = SaveDevelopmentRecordDraftUseCaseStub(
                result: .success(preparedRecord)
            )
            $0.developmentConfirmRecordUseCase = spy
        }

        #expect(store.state.title == baseVersion.title)
        #expect(store.state.markdownContent == baseVersion.markdownContent)
        #expect(store.state.versionNumber == 2)
        #expect(store.state.isCorrection)

        await store.send(.view(.confirm)) {
            $0.isLoading = true
        }
        await store.receive(.store(.preparedForConfirmation(preparedRecord))) {
            $0.record = preparedRecord
            $0.confirmationPreparation = .init(
                record: preparedRecord,
                title: baseVersion.title,
                markdownContent: baseVersion.markdownContent
            )
        }
        await store.receive(.store(.confirmed(version))) {
            $0.isLoading = false
            $0.result = .confirmed(version)
            $0.confirmationPreparation = nil
        }
        await store.receive(.delegate(.confirmed(version)))

        #expect(await spy.requests() == [
            .init(
                goalId: record.goalId,
                recordId: record.id,
                versionId: version.id,
                baseVersionId: baseVersion.id,
                draftRevisionId: preparedRecord.draft?.revisionId
            )
        ])
    }

    @Test("새 기록 생성 재시도는 같은 recordId를 사용한다")
    func 새_기록_생성_재시도는_같은_recordId를_사용한다() async throws {
        let record = try makeDevelopmentRecord(id: "record-1")
        let createSpy = CreateDevelopmentRecordUseCaseSpy(results: [
            .failure(RecordTestError.failed),
            .success(record)
        ])
        let store = TestStore(
            initialState: RecordEditorFeature.State(
                goalId: "goal",
                goalTitle: "개발 목표",
                recordId: record.id
            )
        ) {
            RecordEditorFeature()
        } withDependencies: {
            $0.developmentCreateRecordUseCase = createSpy
        }
        await store.send(.binding(.set(\.title, "기록 제목"))) {
            $0.title = "기록 제목"
        }

        await store.send(.view(.save)) {
            $0.isLoading = true
        }
        await store.receive(.store(.failed)) {
            $0.isLoading = false
            $0.alert = makeRecordErrorAlert("development_record_editor_error_message")
        }
        await store.send(.alert(.dismiss)) {
            $0.alert = nil
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

        #expect(await createSpy.requests().map(\.recordId) == [record.id, record.id])
    }

    @Test("확정 실패 뒤 재시도는 준비된 기록과 versionId를 다시 사용한다")
    func 확정_실패_뒤_재시도는_준비된_기록과_versionId를_다시_사용한다() async throws {
        let record = try makeDevelopmentRecord()
        let version = try makeDevelopmentRecordVersion()
        let createSpy = CreateDevelopmentRecordUseCaseSpy(result: .success(record))
        let confirmSpy = ConfirmDevelopmentRecordUseCaseSpy(results: [
            .failure(RecordTestError.failed),
            .success(version)
        ])
        let store = TestStore(
            initialState: RecordEditorFeature.State(
                goalId: "goal",
                goalTitle: "개발 목표",
                versionId: version.id
            )
        ) {
            RecordEditorFeature()
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
            $0.confirmationPreparation = .init(
                record: record,
                title: "기록 제목",
                markdownContent: ""
            )
        }
        await store.receive(.store(.failed)) {
            $0.isLoading = false
            $0.alert = makeRecordErrorAlert("development_record_editor_error_message")
        }
        await store.send(.alert(.dismiss)) {
            $0.alert = nil
        }
        await store.send(.view(.confirm)) {
            $0.isLoading = true
            $0.result = nil
        }
        await store.receive(.store(.confirmed(version))) {
            $0.isLoading = false
            $0.result = .confirmed(version)
            $0.confirmationPreparation = nil
        }
        await store.receive(.delegate(.confirmed(version)))

        #expect(await createSpy.requests().count == 1)
        #expect(await confirmSpy.requests() == [
            .init(
                goalId: "goal",
                recordId: record.id,
                versionId: version.id,
                baseVersionId: nil,
                draftRevisionId: record.draft?.revisionId
            ),
            .init(
                goalId: "goal",
                recordId: record.id,
                versionId: version.id,
                baseVersionId: nil,
                draftRevisionId: record.draft?.revisionId
            )
        ])
    }

    private func makeStore(
        record: DevelopmentRecord? = nil,
        createResult: Result<DevelopmentRecord, Error>,
        saveResult: Result<DevelopmentRecord, Error>? = nil,
        confirmResult: Result<DevelopmentRecord.Version, Error>
    ) -> TestStoreOf<RecordEditorFeature> {
        TestStore(
            initialState: RecordEditorFeature.State(
                goalId: "goal",
                goalTitle: "개발 목표",
                record: record
            )
        ) {
            RecordEditorFeature()
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
