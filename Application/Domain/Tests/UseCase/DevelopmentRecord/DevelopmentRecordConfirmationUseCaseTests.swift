//
//  DevelopmentRecordConfirmationUseCaseTests.swift
//  DomainTests
//
//  Created by opfic on 9/13/26.
//

import Testing
@testable import Domain

struct DevelopmentRecordConfirmUseCaseTests {
    @Test("최초 Draft 확정은 initial 버전으로 요청한다")
    func 최초_Draft_확정은_initial_버전으로_요청한다() async throws {
        let goal = try makeDevelopmentRecordGoal()
        let record = try makeDevelopmentRecordInitialDraft()
        let version = try makeDevelopmentRecordInitialVersion()
        let repository = DevelopmentRecordRepositorySpy(record: record, confirmedVersion: version)
        let useCase = ConfirmDevelopmentRecordUseCaseImpl(
            repository,
            DevelopmentRecordGoalRepositorySpy(goal: goal),
            idProvider: { "version-1" }
        )

        let result = try await useCase.execute(
            goalId: "goal-1",
            recordId: "record-1",
            baseVersionId: nil
        )

        #expect(result == version)
        #expect(await repository.confirmRequests() == [
            .init(
                goalId: "goal-1",
                recordId: "record-1",
                versionId: "version-1",
                kind: .initial,
                sourceVersionId: nil
            )
        ])
    }

    @Test("확정 버전 기반 Draft 확정은 correction 버전으로 요청한다")
    func 확정_버전_기반_Draft_확정은_correction_버전으로_요청한다() async throws {
        let goal = try makeDevelopmentRecordGoal()
        let currentVersion = try DevelopmentRecord.CurrentVersion(id: "version-1", number: 1)
        let record = try makeDevelopmentRecord(
            currentVersion: currentVersion,
            draft: DevelopmentRecord.Draft(
                title: "정정 초안",
                markdownContent: "본문",
                baseVersionId: currentVersion.id,
                updatedAt: .distantPast
            )
        )
        let version = try makeDevelopmentRecordCorrectionVersion(
            id: "version-2",
            sourceVersionId: currentVersion.id
        )
        let repository = DevelopmentRecordRepositorySpy(record: record, confirmedVersion: version)
        let useCase = ConfirmDevelopmentRecordUseCaseImpl(
            repository,
            DevelopmentRecordGoalRepositorySpy(goal: goal),
            idProvider: { "version-2" }
        )

        _ = try await useCase.execute(
            goalId: "goal-1",
            recordId: "record-1",
            baseVersionId: currentVersion.id
        )

        #expect(await repository.confirmRequests() == [
            .init(
                goalId: "goal-1",
                recordId: "record-1",
                versionId: "version-2",
                kind: .correction,
                sourceVersionId: currentVersion.id
            )
        ])
    }

    @Test("Draft가 없는 기록의 확정을 거부한다")
    func Draft가_없는_기록의_확정을_거부한다() async throws {
        let goal = try makeDevelopmentRecordGoal()
        let repository = DevelopmentRecordRepositorySpy(record: try makeDevelopmentRecordConfirmed())
        let useCase = ConfirmDevelopmentRecordUseCaseImpl(
            repository,
            DevelopmentRecordGoalRepositorySpy(goal: goal)
        )

        await expectDevelopmentRecordDomainError(.developmentRecordDraftNotFound) {
            try await useCase.execute(
                goalId: "goal-1",
                recordId: "record-1",
                baseVersionId: nil
            )
        }
        #expect(await repository.confirmRequests().isEmpty)
    }
}
