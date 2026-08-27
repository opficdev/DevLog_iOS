//
//  DevelopmentRecordMapping.swift
//  Data
//
//  Created by opfic on 8/28/26.
//

import Domain

public extension DevelopmentRecordDraftRequest {
    static func fromDomain(_ draft: DevelopmentRecord.Draft) -> Self {
        Self(
            title: draft.title,
            markdownContent: draft.markdownContent,
            baseVersionId: draft.baseVersionId
        )
    }
}

public extension DevelopmentRecordDraftResponse {
    func toDomain() throws -> DevelopmentRecord.Draft {
        try DevelopmentRecord.Draft(
            title: title,
            markdownContent: markdownContent,
            baseVersionId: baseVersionId,
            updatedAt: updatedAt
        )
    }
}

public extension DevelopmentRecordCurrentVersionResponse {
    func toDomain() throws -> DevelopmentRecord.CurrentVersion {
        try DevelopmentRecord.CurrentVersion(id: id, number: number)
    }
}

public extension DevelopmentRecordResponse {
    func toDomain() throws -> DevelopmentRecord {
        try DevelopmentRecord(
            id: id,
            goalId: goalId,
            currentVersion: try currentVersion?.toDomain(),
            draft: try draft?.toDomain(),
            createdAt: createdAt
        )
    }
}

public extension DevelopmentRecordVersionResponse {
    func toDomain() throws -> DevelopmentRecord.Version {
        try DevelopmentRecord.Version(
            id: id,
            recordId: recordId,
            number: number,
            title: title,
            markdownContent: markdownContent,
            kind: try .fromStorageValue(kind),
            sourceVersionId: sourceVersionId,
            confirmedAt: confirmedAt
        )
    }
}

public extension DevelopmentRecord.Version.Kind {
    var storageValue: String {
        switch self {
        case .initial:
            "initial"
        case .correction:
            "correction"
        case .rollback:
            "rollback"
        }
    }

    static func fromStorageValue(_ value: String) throws -> Self {
        switch value {
        case "initial":
            .initial
        case "correction":
            .correction
        case "rollback":
            .rollback
        default:
            throw DataLayerError.invalidData("DevelopmentRecordVersionResponse.kind: \(value)")
        }
    }
}
