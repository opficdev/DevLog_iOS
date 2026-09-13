//
//  DevelopmentRecordFeatureTestSupport.swift
//  DevelopmentTests
//
//  Created by opfic on 9/13/26.
//

import Domain
import Foundation

enum DevelopmentRecordTestError: Error {
    case failed
}

struct FetchDevelopmentGoalUseCaseStub: FetchDevelopmentGoalUseCase {
    let result: Result<DevelopmentGoal, Error>

    func execute(_ goalId: String) async throws -> DevelopmentGoal {
        try result.get()
    }
}

struct FetchDevelopmentRecordsUseCaseStub: FetchDevelopmentRecordsUseCase {
    let result: Result<[DevelopmentRecord], Error>

    func execute(goalId: String) async throws -> [DevelopmentRecord] {
        try result.get()
    }
}

struct FetchDevelopmentRecordHistoryUseCaseStub: FetchDevelopmentRecordHistoryUseCase {
    let resultByRecordId: [String: Result<[DevelopmentRecord.Version], Error>]

    func execute(
        goalId: String,
        recordId: String
    ) async throws -> [DevelopmentRecord.Version] {
        try resultByRecordId[recordId, default: .failure(DevelopmentRecordTestError.failed)].get()
    }
}

struct CreateDevelopmentRecordUseCaseStub: CreateDevelopmentRecordUseCase {
    let result: Result<DevelopmentRecord, Error>

    func execute(
        goalId: String,
        title: String,
        markdownContent: String
    ) async throws -> DevelopmentRecord {
        try result.get()
    }
}

struct SaveDevelopmentRecordDraftUseCaseStub: SaveDevelopmentRecordDraftUseCase {
    let result: Result<DevelopmentRecord, Error>

    func execute(
        goalId: String,
        recordId: String,
        title: String,
        markdownContent: String
    ) async throws -> DevelopmentRecord {
        try result.get()
    }
}

struct ConfirmDevelopmentRecordUseCaseStub: ConfirmDevelopmentRecordUseCase {
    let result: Result<DevelopmentRecord.Version, Error>

    func execute(goalId: String, recordId: String) async throws -> DevelopmentRecord.Version {
        try result.get()
    }
}

func makeDevelopmentGoal(title: String = "개발 목표") throws -> DevelopmentGoal {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    return try DevelopmentGoal(
        id: "goal",
        title: title,
        description: "설명",
        status: .inProgress,
        createdAt: date,
        updatedAt: date,
        completedAt: nil
    )
}

func makeDevelopmentRecord(
    id: String = "record",
    currentVersion: DevelopmentRecord.CurrentVersion? = nil,
    draft: DevelopmentRecord.Draft? = nil,
    createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
) throws -> DevelopmentRecord {
    try DevelopmentRecord(
        id: id,
        goalId: "goal",
        currentVersion: currentVersion,
        draft: draft ?? makeDevelopmentRecordDraft(),
        createdAt: createdAt
    )
}

func makeConfirmedDevelopmentRecord(
    id: String = "record",
    versionId: String = "version"
) throws -> DevelopmentRecord {
    try DevelopmentRecord(
        id: id,
        goalId: "goal",
        currentVersion: DevelopmentRecord.CurrentVersion(id: versionId, number: 1),
        draft: nil,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000)
    )
}

func makeDevelopmentRecordDraft(
    title: String = "기록 제목",
    markdownContent: String = "# 내용"
) throws -> DevelopmentRecord.Draft {
    try DevelopmentRecord.Draft(
        title: title,
        markdownContent: markdownContent,
        baseVersionId: nil,
        updatedAt: Date(timeIntervalSince1970: 1_700_000_100)
    )
}

func makeDevelopmentRecordVersion(
    id: String = "version",
    recordId: String = "record",
    title: String = "확정 기록"
) throws -> DevelopmentRecord.Version {
    try DevelopmentRecord.Version(
        id: id,
        recordId: recordId,
        number: 1,
        title: title,
        markdownContent: "# 확정 내용",
        kind: .initial,
        sourceVersionId: nil,
        confirmedAt: Date(timeIntervalSince1970: 1_700_000_200)
    )
}
