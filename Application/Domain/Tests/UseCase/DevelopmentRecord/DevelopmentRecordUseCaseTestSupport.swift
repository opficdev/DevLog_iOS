//
//  DevelopmentRecordUseCaseTestSupport.swift
//  DomainTests
//
//  Created by opfic on 8/27/26.
//

import Foundation
import Testing
@testable import Domain

actor DevelopmentGoalRepositorySpy: DevelopmentGoalRepository {
    private let goal: DevelopmentGoal

    init(goal: DevelopmentGoal) {
        self.goal = goal
    }

    func createGoal(
        id: String,
        title: String,
        markdownDescription: String
    ) async throws -> DevelopmentGoal {
        goal
    }

    func fetchGoal(_ goalID: String) async throws -> DevelopmentGoal {
        goal
    }

    func fetchGoals(_ query: DevelopmentGoal.Query) async throws -> [DevelopmentGoal] {
        [goal]
    }

    func fetchCompletionSnapshot(for goalID: String) async throws -> DevelopmentGoal.CompletionSnapshot {
        .init(goal: goal, records: [])
    }

    func transitionGoalStatus(
        _ goalID: String,
        to status: DevelopmentGoal.Status,
        completionSnapshot: DevelopmentGoal.CompletionSnapshot?
    ) async throws { }
}

actor DevelopmentRecordRepositorySpy: DevelopmentRecordRepository {
    struct CreateRequest: Equatable {
        let id: String
        let goalID: String
        let draft: DevelopmentRecord.Draft
    }

    struct RecordQuery: Equatable {
        let goalID: String
        let recordID: String
    }

    struct DraftRequest: Equatable {
        let goalID: String
        let recordID: String
        let draft: DevelopmentRecord.Draft
    }

    struct ConfirmRequest: Equatable {
        let goalID: String
        let recordID: String
        let versionID: String
        let kind: DevelopmentRecord.Version.Kind
        let sourceVersionID: String?
    }

    struct RestoreRequest: Equatable {
        let goalID: String
        let recordID: String
        let versionID: String
        let sourceVersionID: String
    }

    private let createResult: DevelopmentRecord?
    private let records: [DevelopmentRecord]
    private let record: DevelopmentRecord?
    private let versions: [DevelopmentRecord.Version]
    private let savedRecord: DevelopmentRecord?
    private let confirmedVersion: DevelopmentRecord.Version?
    private let restoredVersion: DevelopmentRecord.Version?
    private var recordedCreateRequests = [CreateRequest]()
    private var recordedRecordQueries = [String]()
    private var recordedVersionQueries = [RecordQuery]()
    private var recordedDraftRequests = [DraftRequest]()
    private var recordedConfirmRequests = [ConfirmRequest]()
    private var recordedRestoreRequests = [RestoreRequest]()

    init(
        createResult: DevelopmentRecord? = nil,
        records: [DevelopmentRecord] = [],
        record: DevelopmentRecord? = nil,
        versions: [DevelopmentRecord.Version] = [],
        savedRecord: DevelopmentRecord? = nil,
        confirmedVersion: DevelopmentRecord.Version? = nil,
        restoredVersion: DevelopmentRecord.Version? = nil
    ) {
        self.createResult = createResult
        self.records = records
        self.record = record
        self.versions = versions
        self.savedRecord = savedRecord
        self.confirmedVersion = confirmedVersion
        self.restoredVersion = restoredVersion
    }

    func createRecord(
        id: String,
        goalID: String,
        draft: DevelopmentRecord.Draft
    ) async throws -> DevelopmentRecord {
        recordedCreateRequests.append(.init(id: id, goalID: goalID, draft: draft))
        return try required(createResult)
    }

    func fetchRecords(goalID: String) async throws -> [DevelopmentRecord] {
        recordedRecordQueries.append(goalID)
        return records
    }

    func fetchRecord(goalID: String, recordID: String) async throws -> DevelopmentRecord {
        try required(record)
    }

    func fetchVersions(goalID: String, recordID: String) async throws -> [DevelopmentRecord.Version] {
        recordedVersionQueries.append(.init(goalID: goalID, recordID: recordID))
        return versions
    }

    func saveDraft(
        goalID: String,
        recordID: String,
        draft: DevelopmentRecord.Draft
    ) async throws -> DevelopmentRecord {
        recordedDraftRequests.append(.init(goalID: goalID, recordID: recordID, draft: draft))
        return try required(savedRecord)
    }

    func confirmDraft(
        goalID: String,
        recordID: String,
        versionID: String,
        kind: DevelopmentRecord.Version.Kind,
        sourceVersionID: String?
    ) async throws -> DevelopmentRecord.Version {
        recordedConfirmRequests.append(
            .init(
                goalID: goalID,
                recordID: recordID,
                versionID: versionID,
                kind: kind,
                sourceVersionID: sourceVersionID
            )
        )
        return try required(confirmedVersion)
    }

    func restoreVersion(
        goalID: String,
        recordID: String,
        versionID: String,
        sourceVersionID: String
    ) async throws -> DevelopmentRecord.Version {
        recordedRestoreRequests.append(
            .init(
                goalID: goalID, recordID: recordID, versionID: versionID, sourceVersionID: sourceVersionID)
        )
        return try required(restoredVersion)
    }

    func createRequests() -> [CreateRequest] {
        recordedCreateRequests
    }

    func recordQueries() -> [String] {
        recordedRecordQueries
    }

    func versionQueries() -> [RecordQuery] {
        recordedVersionQueries
    }

    func draftRequests() -> [DraftRequest] {
        recordedDraftRequests
    }

    func confirmRequests() -> [ConfirmRequest] {
        recordedConfirmRequests
    }

    func restoreRequests() -> [RestoreRequest] {
        recordedRestoreRequests
    }
}

enum DevelopmentRecordRepositorySpyError: Error {
    case unconfigured
}

func required<Value>(_ value: Value?) throws -> Value {
    guard let value else {
        throw DevelopmentRecordRepositorySpyError.unconfigured
    }
    return value
}

func makeGoal(
    status: DevelopmentGoal.Status = .inProgress
) throws -> DevelopmentGoal {
    try DevelopmentGoal(
        id: "goal-1",
        title: "개발 목표",
        markdownDescription: "설명",
        status: status,
        createdAt: .distantPast,
        updatedAt: .distantPast,
        completedAt: status == .completed ? .distantPast : nil
    )
}

func makeInitialDraftRecord(
    updatedAt: Date = .distantPast
) throws -> DevelopmentRecord {
    try makeRecord(
        currentVersion: nil,
        draft: DevelopmentRecord.Draft(
            title: "기록",
            markdownContent: "본문",
            baseVersionID: nil,
            updatedAt: updatedAt
        )
    )
}

func makeConfirmedRecord() throws -> DevelopmentRecord {
    try makeRecord(
        currentVersion: DevelopmentRecord.CurrentVersion(id: "version-1", number: 1),
        draft: nil
    )
}

func makeRecord(
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

func makeInitialVersion() throws -> DevelopmentRecord.Version {
    try DevelopmentRecord.Version(
        id: "version-1",
        recordID: "record-1",
        number: 1,
        title: "기록",
        markdownContent: "본문",
        kind: .initial,
        sourceVersionID: nil,
        confirmedAt: .distantPast
    )
}

func makeCorrectionVersion(
    id: String,
    number: Int = 2,
    sourceVersionID: String
) throws -> DevelopmentRecord.Version {
    try DevelopmentRecord.Version(
        id: id,
        recordID: "record-1",
        number: number,
        title: "정정 기록",
        markdownContent: "본문",
        kind: .correction,
        sourceVersionID: sourceVersionID,
        confirmedAt: .distantPast
    )
}

func expectDomainError<Value>(
    _ expected: DomainLayerError,
    operation: () async throws -> Value
) async {
    do {
        _ = try await operation()
        Issue.record("DomainLayerError가 필요")
    } catch let error as DomainLayerError {
        #expect(error == expected)
    } catch {
        Issue.record("예상하지 않은 오류: \(error)")
    }
}
