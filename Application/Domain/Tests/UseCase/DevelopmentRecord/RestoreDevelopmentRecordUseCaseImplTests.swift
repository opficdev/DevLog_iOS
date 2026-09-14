//
//  RestoreDevelopmentRecordUseCaseImplTests.swift
//  DomainTests
//
//  Created by opfic on 9/14/26.
//

import Foundation
import Testing
@testable import Domain

struct RestoreDevelopmentRecordUseCaseImplTests {
    @Test("같은 기록의 과거 버전은 rollback 버전으로 되돌린다")
    func 같은_기록의_과거_버전은_rollback_버전으로_되돌린다() async throws {
        let goal = try makeDevelopmentRecordGoal()
        let currentVersion = try DevelopmentRecord.CurrentVersion(id: "version-3", number: 3)
        let record = try makeDevelopmentRecord(currentVersion: currentVersion, draft: nil)
        let initialVersion = try makeDevelopmentRecordInitialVersion()
        let correctionVersion = try makeDevelopmentRecordCorrectionVersion(
            id: "version-2",
            sourceVersionId: "version-1"
        )
        let currentRecordVersion = try makeDevelopmentRecordCorrectionVersion(
            id: "version-3",
            number: 3,
            sourceVersionId: "version-2"
        )
        let rollbackVersion = try DevelopmentRecord.Version(
            id: "version-4",
            recordId: "record-1",
            number: 4,
            title: "되돌린 기록",
            markdownContent: "본문",
            kind: .rollback,
            sourceVersionId: "version-1",
            confirmedAt: .distantFuture
        )
        let repository = DevelopmentRecordRepositorySpy(
            record: record,
            versions: [initialVersion, correctionVersion, currentRecordVersion],
            restoredVersion: rollbackVersion
        )
        let useCase = RestoreDevelopmentRecordUseCaseImpl(
            repository,
            DevelopmentRecordGoalRepositorySpy(goal: goal)
        )
        let result = try await useCase.execute(
            goalId: "goal-1",
            recordId: "record-1",
            versionId: "version-4",
            sourceVersionId: "version-1"
        )
        #expect(result == rollbackVersion)
        #expect(await repository.restoreRequests() == [
            .init(
                goalId: "goal-1",
                recordId: "record-1",
                versionId: "version-4",
                sourceVersionId: "version-1"
            )
        ])
    }

    @Test("되돌리기 응답이 유실되면 같은 버전 ID로 성공 결과를 복구한다")
    func 되돌리기_응답이_유실되면_같은_버전_ID로_성공_결과를_복구한다() async throws {
        let goal = try makeDevelopmentRecordGoal()
        let currentVersion = try DevelopmentRecord.CurrentVersion(id: "version-3", number: 3)
        let restoredCurrentVersion = try DevelopmentRecord.CurrentVersion(id: "version-4", number: 4)
        let record = try makeDevelopmentRecord(currentVersion: currentVersion, draft: nil)
        let restoredRecord = try makeDevelopmentRecord(
            currentVersion: restoredCurrentVersion,
            draft: nil
        )
        let initialVersion = try makeDevelopmentRecordInitialVersion()
        let rollbackVersion = try DevelopmentRecord.Version(
            id: restoredCurrentVersion.id,
            recordId: "record-1",
            number: restoredCurrentVersion.number,
            title: initialVersion.title,
            markdownContent: initialVersion.markdownContent,
            kind: .rollback,
            sourceVersionId: initialVersion.id,
            confirmedAt: .distantFuture
        )
        let repository = DevelopmentRecordRepositorySpy(
            record: record,
            subsequentRecords: [restoredRecord],
            versions: [initialVersion, rollbackVersion],
            restoreError: DevelopmentRecordRepositorySpyError.unconfigured
        )
        let useCase = RestoreDevelopmentRecordUseCaseImpl(
            repository,
            DevelopmentRecordGoalRepositorySpy(goal: goal)
        )

        let result = try await useCase.execute(
            goalId: "goal-1",
            recordId: record.id,
            versionId: rollbackVersion.id,
            sourceVersionId: initialVersion.id
        )

        #expect(result == rollbackVersion)
        #expect(await repository.restoreRequests() == [
            .init(
                goalId: "goal-1",
                recordId: record.id,
                versionId: rollbackVersion.id,
                sourceVersionId: initialVersion.id
            )
        ])
        #expect(await repository.exactVersionQueries() == [
            .init(
                goalId: "goal-1",
                recordId: record.id,
                versionId: rollbackVersion.id
            )
        ])
    }

    @Test("현재 또는 다른 기록의 버전은 되돌리기 대상으로 거부한다")
    func 현재_또는_다른_기록의_버전은_되돌리기_대상으로_거부한다() async throws {
        let goal = try makeDevelopmentRecordGoal()
        let currentVersion = try DevelopmentRecord.CurrentVersion(id: "version-2", number: 2)
        let record = try makeDevelopmentRecord(currentVersion: currentVersion, draft: nil)
        let currentRecordVersion = try makeDevelopmentRecordCorrectionVersion(
            id: "version-2",
            number: 2,
            sourceVersionId: "version-1"
        )
        let otherRecordVersion = try DevelopmentRecord.Version(
            id: "other-version-1",
            recordId: "record-2",
            number: 1,
            title: "다른 기록",
            markdownContent: "본문",
            kind: .initial,
            sourceVersionId: nil,
            confirmedAt: .distantPast
        )
        for sourceVersionId in [currentRecordVersion.id, otherRecordVersion.id] {
            let repository = DevelopmentRecordRepositorySpy(
                record: record,
                versions: [currentRecordVersion, otherRecordVersion]
            )
            let useCase = RestoreDevelopmentRecordUseCaseImpl(
                repository,
                DevelopmentRecordGoalRepositorySpy(goal: goal)
            )

            await expectDevelopmentRecordDomainError(.developmentRecordVersionNotFound) {
                try await useCase.execute(
                    goalId: "goal-1",
                    recordId: "record-1",
                    versionId: "version-3",
                    sourceVersionId: sourceVersionId
                )
            }
            #expect(await repository.restoreRequests().isEmpty)
        }
    }

    @Test("Draft가 있으면 버전 되돌리기를 거부한다")
    func Draft가_있으면_버전_되돌리기를_거부한다() async throws {
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
        let repository = DevelopmentRecordRepositorySpy(record: record)
        let useCase = RestoreDevelopmentRecordUseCaseImpl(
            repository,
            DevelopmentRecordGoalRepositorySpy(goal: goal)
        )

        await expectDevelopmentRecordDomainError(.developmentRecordDraftConflict) {
            try await useCase.execute(
                goalId: "goal-1",
                recordId: "record-1",
                versionId: "version-2",
                sourceVersionId: "version-1"
            )
        }
        #expect(await repository.restoreRequests().isEmpty)
    }
}
