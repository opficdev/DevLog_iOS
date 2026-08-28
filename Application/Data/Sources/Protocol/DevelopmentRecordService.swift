//
//  DevelopmentRecordService.swift
//  Data
//
//  Created by opfic on 8/28/26.
//

public protocol DevelopmentRecordService {
    func createRecord(
        goalId: String,
        recordId: String,
        request: DevelopmentRecordCreateRequest
    ) async throws -> DevelopmentRecordResponse
    func fetchRecords(goalId: String) async throws -> [DevelopmentRecordResponse]
    func fetchRecord(goalId: String, recordId: String) async throws -> DevelopmentRecordResponse
    func fetchVersions(
        goalId: String,
        recordId: String
    ) async throws -> [DevelopmentRecordVersionResponse]
    func saveDraft(
        goalId: String,
        recordId: String,
        request: DevelopmentRecordDraftRequest
    ) async throws -> DevelopmentRecordResponse
    func confirmDraft(
        goalId: String,
        recordId: String,
        request: DevelopmentRecordConfirmationRequest
    ) async throws -> DevelopmentRecordVersionResponse
    func restoreVersion(
        goalId: String,
        recordId: String,
        request: DevelopmentRecordRestoreRequest
    ) async throws -> DevelopmentRecordVersionResponse
}
