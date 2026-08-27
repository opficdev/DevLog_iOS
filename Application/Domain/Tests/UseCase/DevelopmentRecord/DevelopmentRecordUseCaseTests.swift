//
//  DevelopmentRecordUseCaseTests.swift
//  DomainTests
//
//  Created by opfic on 8/27/26.
//

import Foundation
import Testing
@testable import Domain

struct DevelopmentRecordUseCaseTests {
    @Test("진행 중 목표에서 최초 Draft와 함께 기록을 생성한다")
    func 진행_중_목표에서_최초_Draft와_함께_기록을_생성한다() async throws {
        let goal = try makeGoal()
        let createdAt = Date(timeIntervalSinceReferenceDate: 10)
        let record = try makeInitialDraftRecord(updatedAt: createdAt)
        let repository = DevelopmentRecordRepositorySpy(createResult: record)
        let useCase = CreateDevelopmentRecordUseCaseImpl(
            repository,
            DevelopmentGoalRepositorySpy(goal: goal),
            idProvider: { "record-1" },
            now: { createdAt }
        )
        let result = try await useCase.execute(
            goalID: "goal-1",
            title: "기록",
            markdownContent: "본문"
        )

        #expect(result == record)
        #expect(await repository.createRequests() == [
            .init(
                id: "record-1",
                goalID: "goal-1",
                draft: try DevelopmentRecord.Draft(
                    title: "기록",
                    markdownContent: "본문",
                    baseVersionID: nil,
                    updatedAt: createdAt
                )
            )
        ])
    }

    @Test("완료 또는 보관 목표에서 기록 생성을 거부한다")
    func 완료_또는_보관_목표에서_기록_생성을_거부한다() async throws {
        for status in [DevelopmentGoal.Status.completed, .archived] {
            let repository = DevelopmentRecordRepositorySpy()
            let useCase = CreateDevelopmentRecordUseCaseImpl(
                repository,
            DevelopmentGoalRepositorySpy(goal: try makeGoal(status: status))
            )
            await expectDomainError(.developmentGoalIsNotInProgress) {
                try await useCase.execute(
                    goalID: "goal-1",
                    title: "기록",
                    markdownContent: "본문"
                )
            }
            #expect(await repository.createRequests().isEmpty)
        }
    }

    @Test("기록 목록 조회는 Repository 결과를 반환한다")
    func 기록_목록_조회는_Repository_결과를_반환한다() async throws {
        let record = try makeInitialDraftRecord()
        let repository = DevelopmentRecordRepositorySpy(records: [record])
        let useCase = FetchDevelopmentRecordsUseCaseImpl(repository)
        let result = try await useCase.execute(goalID: "goal-1")
        #expect(result == [record])
        #expect(await repository.recordQueries() == ["goal-1"])
    }

    @Test("기록 이력 조회는 Repository 결과를 반환한다")
    func 기록_이력_조회는_Repository_결과를_반환한다() async throws {
        let initialVersion = try makeInitialVersion()
        let repository = DevelopmentRecordRepositorySpy(versions: [initialVersion])
        let useCase = FetchDevelopmentRecordHistoryUseCaseImpl(repository)
        let result = try await useCase.execute(goalID: "goal-1", recordID: "record-1")
        #expect(result == [initialVersion])
        #expect(await repository.versionQueries() == [
            .init(goalID: "goal-1", recordID: "record-1")
        ])
    }

    @Test("최초 Draft 저장은 기준 버전 없이 갱신한다")
    func 최초_Draft_저장은_기준_버전_없이_갱신한다() async throws {
        let goal = try makeGoal()
        let record = try makeInitialDraftRecord()
        let savedRecord = try makeInitialDraftRecord()
        let updatedAt = Date(timeIntervalSinceReferenceDate: 20)
        let repository = DevelopmentRecordRepositorySpy(record: record, savedRecord: savedRecord)
        let useCase = SaveDevelopmentRecordDraftUseCaseImpl(
            repository,
            DevelopmentGoalRepositorySpy(goal: goal),
            now: { updatedAt }
        )
        let result = try await useCase.execute(
            goalID: "goal-1",
            recordID: "record-1",
            title: "수정 기록",
            markdownContent: "수정 본문"
        )

        #expect(result == savedRecord)
        #expect(await repository.draftRequests() == [
            .init(
                goalID: "goal-1",
                recordID: "record-1",
                draft: try DevelopmentRecord.Draft(
                    title: "수정 기록",
                    markdownContent: "수정 본문",
                    baseVersionID: nil,
                    updatedAt: updatedAt
                )
            )
        ])
    }

    @Test("확정 버전 기반 Draft 저장은 기준 버전을 유지한다")
    func 확정_버전_기반_Draft_저장은_기준_버전을_유지한다() async throws {
        let goal = try makeGoal()
        let currentVersion = try DevelopmentRecord.CurrentVersion(id: "version-1", number: 1)
        let record = try makeRecord(
            currentVersion: currentVersion,
            draft: DevelopmentRecord.Draft(
                title: "정정 초안",
                markdownContent: "본문",
                baseVersionID: currentVersion.id,
                updatedAt: .distantPast
            )
        )
        let savedRecord = try makeRecord(
            currentVersion: currentVersion,
            draft: DevelopmentRecord.Draft(
                title: "수정 정정 초안",
                markdownContent: "수정 본문",
                baseVersionID: currentVersion.id,
                updatedAt: .distantFuture
            )
        )
        let updatedAt = Date(timeIntervalSinceReferenceDate: 30)
        let repository = DevelopmentRecordRepositorySpy(record: record, savedRecord: savedRecord)
        let useCase = SaveDevelopmentRecordDraftUseCaseImpl(
            repository,
            DevelopmentGoalRepositorySpy(goal: goal),
            now: { updatedAt }
        )
        _ = try await useCase.execute(
            goalID: "goal-1",
            recordID: "record-1",
            title: "수정 정정 초안",
            markdownContent: "수정 본문"
        )

        let requests = await repository.draftRequests()
        #expect(requests.first?.draft.baseVersionID == currentVersion.id)
        #expect(requests.first?.draft.updatedAt == updatedAt)
    }

    @Test("확정 기록의 저장은 현재 버전 기준 정정 Draft를 시작한다")
    func 확정_기록의_저장은_현재_버전_기준_정정_Draft를_시작한다() async throws {
        let goal = try makeGoal()
        let record = try makeConfirmedRecord()
        let currentVersion = try #require(record.currentVersion)
        let savedRecord = try makeRecord(
            currentVersion: currentVersion,
            draft: DevelopmentRecord.Draft(
                title: "정정 초안",
                markdownContent: "본문",
                baseVersionID: currentVersion.id,
                updatedAt: .distantFuture
            )
        )
        let updatedAt = Date(timeIntervalSinceReferenceDate: 40)
        let repository = DevelopmentRecordRepositorySpy(record: record, savedRecord: savedRecord)
        let useCase = SaveDevelopmentRecordDraftUseCaseImpl(
            repository,
            DevelopmentGoalRepositorySpy(goal: goal),
            now: { updatedAt }
        )
        let result = try await useCase.execute(
            goalID: "goal-1",
            recordID: "record-1",
            title: "정정 초안",
            markdownContent: "본문"
        )

        #expect(result == savedRecord)
        #expect(await repository.draftRequests() == [
            .init(
                goalID: "goal-1",
                recordID: "record-1",
                draft: try DevelopmentRecord.Draft(
                    title: "정정 초안",
                    markdownContent: "본문",
                    baseVersionID: currentVersion.id,
                    updatedAt: updatedAt
                )
            )
        ])
    }

    @Test("최초 Draft 확정은 initial 버전으로 요청한다")
    func 최초_Draft_확정은_initial_버전으로_요청한다() async throws {
        let goal = try makeGoal()
        let record = try makeInitialDraftRecord()
        let version = try makeInitialVersion()
        let repository = DevelopmentRecordRepositorySpy(record: record, confirmedVersion: version)
        let useCase = ConfirmDevelopmentRecordUseCaseImpl(
            repository,
            DevelopmentGoalRepositorySpy(goal: goal),
            idProvider: { "version-1" }
        )

        let result = try await useCase.execute(goalID: "goal-1", recordID: "record-1")

        #expect(result == version)
        #expect(await repository.confirmRequests() == [
            .init(
                goalID: "goal-1",
                recordID: "record-1",
                versionID: "version-1",
                kind: .initial,
                sourceVersionID: nil
            )
        ])
    }

    @Test("확정 버전 기반 Draft 확정은 correction 버전으로 요청한다")
    func 확정_버전_기반_Draft_확정은_correction_버전으로_요청한다() async throws {
        let goal = try makeGoal()
        let currentVersion = try DevelopmentRecord.CurrentVersion(id: "version-1", number: 1)
        let record = try makeRecord(
            currentVersion: currentVersion,
            draft: DevelopmentRecord.Draft(
                title: "정정 초안",
                markdownContent: "본문",
                baseVersionID: currentVersion.id,
                updatedAt: .distantPast
            )
        )
        let version = try makeCorrectionVersion(id: "version-2", sourceVersionID: currentVersion.id)
        let repository = DevelopmentRecordRepositorySpy(record: record, confirmedVersion: version)
        let useCase = ConfirmDevelopmentRecordUseCaseImpl(
            repository,
            DevelopmentGoalRepositorySpy(goal: goal),
            idProvider: { "version-2" }
        )

        _ = try await useCase.execute(goalID: "goal-1", recordID: "record-1")

        #expect(await repository.confirmRequests() == [
            .init(
                goalID: "goal-1",
                recordID: "record-1",
                versionID: "version-2",
                kind: .correction,
                sourceVersionID: currentVersion.id
            )
        ])
    }

    @Test("Draft가 없는 기록의 확정을 거부한다")
    func Draft가_없는_기록의_확정을_거부한다() async throws {
        let goal = try makeGoal()
        let repository = DevelopmentRecordRepositorySpy(record: try makeConfirmedRecord())
        let useCase = ConfirmDevelopmentRecordUseCaseImpl(
            repository,
            DevelopmentGoalRepositorySpy(goal: goal)
        )

        await expectDomainError(.developmentRecordDraftNotFound) {
            try await useCase.execute(goalID: "goal-1", recordID: "record-1")
        }
        #expect(await repository.confirmRequests().isEmpty)
    }

    @Test("같은 기록의 과거 버전은 rollback 버전으로 되돌린다")
    func 같은_기록의_과거_버전은_rollback_버전으로_되돌린다() async throws {
        let goal = try makeGoal()
        let currentVersion = try DevelopmentRecord.CurrentVersion(id: "version-3", number: 3)
        let record = try makeRecord(currentVersion: currentVersion, draft: nil)
        let initialVersion = try makeInitialVersion()
        let correctionVersion = try makeCorrectionVersion(id: "version-2", sourceVersionID: "version-1")
        let currentRecordVersion = try makeCorrectionVersion(
            id: "version-3",
            number: 3,
            sourceVersionID: "version-2"
        )
        let rollbackVersion = try DevelopmentRecord.Version(
            id: "version-4",
            recordID: "record-1",
            number: 4,
            title: "되돌린 기록",
            markdownContent: "본문",
            kind: .rollback,
            sourceVersionID: "version-1",
            confirmedAt: .distantFuture
        )
        let repository = DevelopmentRecordRepositorySpy(
            record: record,
            versions: [initialVersion, correctionVersion, currentRecordVersion],
            restoredVersion: rollbackVersion
        )
        let useCase = RestoreDevelopmentRecordUseCaseImpl(
            repository,
            DevelopmentGoalRepositorySpy(goal: goal),
            idProvider: { "version-4" }
        )

        let result = try await useCase.execute(
            goalID: "goal-1",
            recordID: "record-1",
            sourceVersionID: "version-1"
        )

        #expect(result == rollbackVersion)
        #expect(await repository.restoreRequests() == [
            .init(
                goalID: "goal-1",
                recordID: "record-1",
                versionID: "version-4",
                sourceVersionID: "version-1"
            )
        ])
    }

    @Test("현재 또는 다른 기록의 버전은 되돌리기 대상으로 거부한다")
    func 현재_또는_다른_기록의_버전은_되돌리기_대상으로_거부한다() async throws {
        let goal = try makeGoal()
        let currentVersion = try DevelopmentRecord.CurrentVersion(id: "version-2", number: 2)
        let record = try makeRecord(currentVersion: currentVersion, draft: nil)
        let currentRecordVersion = try makeCorrectionVersion(
            id: "version-2",
            number: 2,
            sourceVersionID: "version-1"
        )
        let otherRecordVersion = try DevelopmentRecord.Version(
            id: "other-version-1",
            recordID: "record-2",
            number: 1,
            title: "다른 기록",
            markdownContent: "본문",
            kind: .initial,
            sourceVersionID: nil,
            confirmedAt: .distantPast
        )

        for sourceVersionID in [currentRecordVersion.id, otherRecordVersion.id] {
            let repository = DevelopmentRecordRepositorySpy(
                record: record,
                versions: [currentRecordVersion, otherRecordVersion]
            )
            let useCase = RestoreDevelopmentRecordUseCaseImpl(
                repository,
                DevelopmentGoalRepositorySpy(goal: goal)
            )

            await expectDomainError(.developmentRecordVersionNotFound) {
                try await useCase.execute(
                    goalID: "goal-1",
                    recordID: "record-1",
                    sourceVersionID: sourceVersionID
                )
            }
            #expect(await repository.restoreRequests().isEmpty)
        }
    }

    @Test("Draft가 있으면 버전 되돌리기를 거부한다")
    func Draft가_있으면_버전_되돌리기를_거부한다() async throws {
        let goal = try makeGoal()
        let currentVersion = try DevelopmentRecord.CurrentVersion(id: "version-1", number: 1)
        let record = try makeRecord(
            currentVersion: currentVersion,
            draft: DevelopmentRecord.Draft(
                title: "정정 초안",
                markdownContent: "본문",
                baseVersionID: currentVersion.id,
                updatedAt: .distantPast
            )
        )
        let repository = DevelopmentRecordRepositorySpy(record: record)
        let useCase = RestoreDevelopmentRecordUseCaseImpl(
            repository,
            DevelopmentGoalRepositorySpy(goal: goal)
        )

        await expectDomainError(.developmentRecordDraftConflict) {
            try await useCase.execute(
                goalID: "goal-1",
                recordID: "record-1",
                sourceVersionID: "version-1"
            )
        }
        #expect(await repository.restoreRequests().isEmpty)
    }
}
