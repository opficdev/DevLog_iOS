//
//  DevelopmentRecordRepository.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol DevelopmentRecordRepository {
    func createRecord(
        id: String,
        goalID: String,
        draft: DevelopmentRecord.Draft
    ) async throws -> DevelopmentRecord
    func fetchRecords(goalID: String) async throws -> [DevelopmentRecord]
    func fetchRecord(goalID: String, recordID: String) async throws -> DevelopmentRecord
    func fetchVersions(goalID: String, recordID: String) async throws -> [DevelopmentRecord.Version]
    func saveDraft(
        goalID: String,
        recordID: String,
        draft: DevelopmentRecord.Draft
    ) async throws -> DevelopmentRecord
    func confirmDraft(
        goalID: String,
        recordID: String,
        versionID: String,
        kind: DevelopmentRecord.Version.Kind,
        sourceVersionID: String?
    ) async throws -> DevelopmentRecord.Version
    func restoreVersion(
        goalID: String,
        recordID: String,
        versionID: String,
        sourceVersionID: String
    ) async throws -> DevelopmentRecord.Version
}
