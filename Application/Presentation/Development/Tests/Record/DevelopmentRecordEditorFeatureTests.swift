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
