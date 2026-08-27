//
//  DevelopmentRecordTests.swift
//  DomainTests
//
//  Created by opfic on 8/27/26.
//

import Foundation
import Testing
@testable import Domain

struct DevelopmentRecordTests {
    @Test("공백과 줄바꿈만 있는 기록 제목은 거부한다")
    func 공백과_줄바꿈만_있는_기록_제목은_거부한다() {
        expectDomainError(.invalidDevelopmentRecordTitle) {
            _ = try makeDraft(title: "\n ")
        }
    }

    @Test("현재 버전은 ID와 1 이상의 번호를 함께 가진다")
    func 현재_버전은_ID와_1_이상의_번호를_함께_가진다() throws {
        let version = try DevelopmentRecord.CurrentVersion(id: "version-1", number: 1)

        #expect(version.id == "version-1")
        #expect(version.number == 1)
    }

    @Test("현재 버전의 빈 ID와 0 이하 번호는 거부한다")
    func 현재_버전의_빈_ID와_0_이하_번호는_거부한다() {
        expectDomainError(.invalidDevelopmentRecordCurrentVersion) {
            _ = try DevelopmentRecord.CurrentVersion(id: "", number: 1)
        }
        expectDomainError(.invalidDevelopmentRecordCurrentVersion) {
            _ = try DevelopmentRecord.CurrentVersion(id: "version-1", number: 0)
        }
    }

    @Test("최초 초안 기록은 현재 버전 없이 생성한다")
    func 최초_초안_기록은_현재_버전_없이_생성한다() throws {
        let draft = try makeDraft()
        let record = try makeRecord(currentVersion: nil, draft: draft)

        #expect(record.currentVersion == nil)
        #expect(record.draft == draft)
    }

    @Test("현재 버전이 없는 기록은 기준 버전을 가진 초안을 가질 수 없다")
    func 현재_버전이_없는_기록은_기준_버전을_가진_초안을_가질_수_없다() throws {
        let draft = try makeDraft(baseVersionID: "version-1")

        expectDomainError(.invalidDevelopmentRecordCurrentVersion) {
            _ = try makeRecord(currentVersion: nil, draft: draft)
        }
    }

    @Test("현재 버전 기반 초안은 같은 현재 버전을 기준으로 가진다")
    func 현재_버전_기반_초안은_같은_현재_버전을_기준으로_가진다() throws {
        let currentVersion = try DevelopmentRecord.CurrentVersion(id: "version-2", number: 2)
        let draft = try makeDraft(baseVersionID: "version-2")
        let record = try makeRecord(currentVersion: currentVersion, draft: draft)

        #expect(record.currentVersion == currentVersion)
        #expect(record.draft == draft)
    }

    @Test("확정된 기록은 초안 없이 현재 버전을 가진다")
    func 확정된_기록은_초안_없이_현재_버전을_가진다() throws {
        let currentVersion = try DevelopmentRecord.CurrentVersion(id: "version-2", number: 2)
        let record = try makeRecord(currentVersion: currentVersion, draft: nil)

        #expect(record.currentVersion == currentVersion)
        #expect(record.draft == nil)
    }

    @Test("현재 버전과 다른 기준 버전을 가진 초안은 거부한다")
    func 현재_버전과_다른_기준_버전을_가진_초안은_거부한다() throws {
        let currentVersion = try DevelopmentRecord.CurrentVersion(id: "version-2", number: 2)
        let draft = try makeDraft(baseVersionID: "version-1")

        expectDomainError(.invalidDevelopmentRecordCurrentVersion) {
            _ = try makeRecord(currentVersion: currentVersion, draft: draft)
        }
    }

    @Test("현재 버전이 있는 기록은 기준 버전 없는 초안을 가질 수 없다")
    func 현재_버전이_있는_기록은_기준_버전_없는_초안을_가질_수_없다() throws {
        let currentVersion = try DevelopmentRecord.CurrentVersion(id: "version-2", number: 2)
        let draft = try makeDraft()

        expectDomainError(.invalidDevelopmentRecordCurrentVersion) {
            _ = try makeRecord(currentVersion: currentVersion, draft: draft)
        }
    }

    @Test("최초 확정 버전은 출처를 가지지 않는다")
    func 최초_확정_버전은_출처를_가지지_않는다() throws {
        let version = try makeVersion(kind: .initial, sourceVersionID: nil)

        #expect(version.sourceVersionID == nil)
    }

    @Test("정정과 되돌리기 버전은 출처를 가진다")
    func 정정과_되돌리기_버전은_출처를_가진다() throws {
        let correction = try makeVersion(kind: .correction, sourceVersionID: "version-1")
        let rollback = try makeVersion(kind: .rollback, sourceVersionID: "version-1")

        #expect(correction.sourceVersionID == "version-1")
        #expect(rollback.sourceVersionID == "version-1")
    }

    @Test("버전 종류와 출처 관계가 맞지 않으면 거부한다")
    func 버전_종류와_출처_관계가_맞지_않으면_거부한다() {
        expectDomainError(.invalidDevelopmentRecordVersion) {
            _ = try makeVersion(kind: .initial, sourceVersionID: "version-1")
        }
        expectDomainError(.invalidDevelopmentRecordVersion) {
            _ = try makeVersion(kind: .correction, sourceVersionID: nil)
        }
    }

    @Test("최초 확정 버전은 1번이어야 한다")
    func 최초_확정_버전은_1번이어야_한다() {
        expectDomainError(.invalidDevelopmentRecordVersion) {
            _ = try makeVersion(kind: .initial, sourceVersionID: nil, number: 2)
        }
    }

    @Test("정정과 되돌리기 버전은 2번부터 시작한다")
    func 정정과_되돌리기_버전은_2번부터_시작한다() {
        expectDomainError(.invalidDevelopmentRecordVersion) {
            _ = try makeVersion(kind: .correction, sourceVersionID: "version-1", number: 1)
        }
    }
}

private func makeDraft(
    title: String = "기록 제목",
    baseVersionID: String? = nil
) throws -> DevelopmentRecord.Draft {
    try DevelopmentRecord.Draft(
        title: title,
        markdownContent: "기록 본문",
        baseVersionID: baseVersionID,
        updatedAt: .distantPast
    )
}

private func makeRecord(
    currentVersion: DevelopmentRecord.CurrentVersion?,
    draft: DevelopmentRecord.Draft?
) throws -> DevelopmentRecord {
    try DevelopmentRecord(
        id: "record-1",
        goalID: "goal-1",
        currentVersion: currentVersion,
        draft: draft,
        createdAt: .distantPast
    )
}

private func makeVersion(
    kind: DevelopmentRecord.Version.Kind,
    sourceVersionID: String?,
    number: Int? = nil
) throws -> DevelopmentRecord.Version {
    try DevelopmentRecord.Version(
        id: "version-2",
        recordID: "record-1",
        number: number ?? (kind == .initial ? 1 : 2),
        title: "확정 제목",
        markdownContent: "확정 본문",
        kind: kind,
        sourceVersionID: sourceVersionID,
        confirmedAt: .distantFuture
    )
}

private func expectDomainError(
    _ expected: DomainLayerError,
    operation: () throws -> Void
) {
    do {
        try operation()
        Issue.record("DomainLayerError가 필요")
    } catch let error as DomainLayerError {
        #expect(error == expected)
    } catch {
        Issue.record("예상하지 않은 오류: \(error)")
    }
}
