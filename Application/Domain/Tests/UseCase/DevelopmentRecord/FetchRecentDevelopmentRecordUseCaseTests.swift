//
//  FetchRecentDevelopmentRecordUseCaseTests.swift
//  DomainTests
//
//  Created by opfic on 10/5/26.
//

import Foundation
import Testing
@testable import Domain

struct FetchRecentDevelopmentRecordUseCaseTests {
    @Test("각 기록의 현재 확정 버전 중 확정 시각이 가장 늦은 버전을 반환한다")
    func latestConfirmedVersion() async throws {
        let olderRecord = try makeRecentRecordFixture(id: "older-record", number: 2, confirmedAt: 300, createdAt: 0)
        let newerRecord = try makeRecentRecordFixture(id: "newer-record", number: 1, confirmedAt: 200, createdAt: 100)
        let spy = DevelopmentRecordRepositorySpy(
            records: [newerRecord.record, olderRecord.record],
            versions: [newerRecord.version, olderRecord.version]
        )
        let useCase = FetchRecentDevelopmentRecordUseCaseImpl(spy)

        let version = try await useCase.execute(goalId: "goal-1")

        #expect(version == olderRecord.version)
        #expect(await spy.recordQueries() == ["goal-1"])
        #expect(await spy.exactVersionQueries().sorted { $0.recordId < $1.recordId } == [
            .init(goalId: "goal-1", recordId: "newer-record", versionId: newerRecord.version.id),
            .init(goalId: "goal-1", recordId: "older-record", versionId: olderRecord.version.id)
        ])
    }

    @Test("현재 확정 버전이 없는 기록은 건너뛴다")
    func skipsDrafts() async throws {
        let record = try makeDevelopmentRecordInitialDraft(updatedAt: .now)
        let confirmedRecord = try makeRecentRecordFixture(id: "confirmed", number: 1, confirmedAt: 100, createdAt: 0)
        let spy = DevelopmentRecordRepositorySpy(
            records: [record, confirmedRecord.record],
            versions: [confirmedRecord.version]
        )
        let useCase = FetchRecentDevelopmentRecordUseCaseImpl(spy)

        let version = try await useCase.execute(goalId: "goal-1")

        #expect(version == confirmedRecord.version)
        #expect(await spy.exactVersionQueries() == [
            .init(goalId: "goal-1", recordId: "confirmed", versionId: confirmedRecord.version.id)
        ])
    }

    @Test("버전 조회가 실패하면 성공한 다른 버전이 있어도 오류를 그대로 던진다")
    func versionFailure() async throws {
        let record = try makeDevelopmentRecordConfirmed()
        let confirmedRecord = try makeRecentRecordFixture(id: "confirmed", number: 1, confirmedAt: 100, createdAt: 0)
        let spy = DevelopmentRecordRepositorySpy(
            records: [record, confirmedRecord.record],
            versions: [confirmedRecord.version]
        )
        let useCase = FetchRecentDevelopmentRecordUseCaseImpl(spy)

        await #expect(throws: DevelopmentRecordRepositorySpyError.self) {
            try await useCase.execute(goalId: "goal-1")
        }
    }


}

private func makeRecentRecordFixture(
    id: String,
    number: Int,
    confirmedAt: TimeInterval,
    createdAt: TimeInterval
) throws -> (record: DevelopmentRecord, version: DevelopmentRecord.Version) {
    let version = try DevelopmentRecord.Version(
        id: "\(id)-v\(number)",
        recordId: id,
        number: number,
        title: "기록",
        markdownContent: "본문",
        kind: number == 1 ? .initial : .correction,
        sourceVersionId: number == 1 ? nil : "\(id)-v\(number - 1)",
        confirmedAt: Date(timeIntervalSince1970: confirmedAt)
    )
    let record = try DevelopmentRecord(
        id: id,
        goalId: "goal-1",
        currentVersion: .init(id: version.id, number: number),
        draft: nil,
        createdAt: Date(timeIntervalSince1970: createdAt)
    )
    return (record, version)
}
