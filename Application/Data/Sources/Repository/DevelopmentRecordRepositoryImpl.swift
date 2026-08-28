//
//  DevelopmentRecordRepositoryImpl.swift
//  Data
//
//  Created by opfic on 8/28/26.
//

import Domain

final class DevelopmentRecordRepositoryImpl: DevelopmentRecordRepository {
    private let service: DevelopmentRecordService

    init(service: DevelopmentRecordService) {
        self.service = service
    }

    func createRecord(
        id: String,
        goalId: String,
        draft: DevelopmentRecord.Draft
    ) async throws -> DevelopmentRecord {
        do {
            let response = try await service.createRecord(
                goalId: goalId,
                recordId: id,
                request: .init(draft: .fromDomain(draft))
            )
            return try response.toDomain()
        } catch {
            throw error.toDomain()
        }
    }

    func fetchRecords(goalId: String) async throws -> [DevelopmentRecord] {
        do {
            return try await service.fetchRecords(goalId: goalId).map { try $0.toDomain() }
        } catch {
            throw error.toDomain()
        }
    }

    func fetchRecord(goalId: String, recordId: String) async throws -> DevelopmentRecord {
        do {
            return try await service.fetchRecord(goalId: goalId, recordId: recordId).toDomain()
        } catch {
            throw error.toDomain()
        }
    }

    func fetchVersions(
        goalId: String,
        recordId: String
    ) async throws -> [DevelopmentRecord.Version] {
        do {
            return try await service.fetchVersions(goalId: goalId, recordId: recordId).map { try $0.toDomain() }
        } catch {
            throw error.toDomain()
        }
    }

    func saveDraft(
        goalId: String,
        recordId: String,
        draft: DevelopmentRecord.Draft
    ) async throws -> DevelopmentRecord {
        do {
            let response = try await service.saveDraft(
                goalId: goalId,
                recordId: recordId,
                request: .fromDomain(draft)
            )
            return try response.toDomain()
        } catch {
            throw error.toDomain()
        }
    }

    func confirmDraft(
        goalId: String,
        recordId: String,
        versionId: String,
        kind: DevelopmentRecord.Version.Kind,
        sourceVersionId: String?
    ) async throws -> DevelopmentRecord.Version {
        do {
            let response = try await service.confirmDraft(
                goalId: goalId,
                recordId: recordId,
                request: .init(
                    versionId: versionId,
                    kind: kind.storageValue,
                    sourceVersionId: sourceVersionId
                )
            )
            return try response.toDomain()
        } catch {
            throw error.toDomain()
        }
    }

    func restoreVersion(
        goalId: String,
        recordId: String,
        versionId: String,
        sourceVersionId: String
    ) async throws -> DevelopmentRecord.Version {
        do {
            let response = try await service.restoreVersion(
                goalId: goalId,
                recordId: recordId,
                request: .init(versionId: versionId, sourceVersionId: sourceVersionId)
            )
            return try response.toDomain()
        } catch {
            throw error.toDomain()
        }
    }
}
