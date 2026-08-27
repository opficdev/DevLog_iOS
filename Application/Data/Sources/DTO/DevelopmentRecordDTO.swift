//
//  DevelopmentRecordDTO.swift
//  Data
//
//  Created by opfic on 8/28/26.
//

import Foundation

public struct DevelopmentRecordDraftRequest: Encodable {
    public let title: String
    public let markdownContent: String
    public let baseVersionId: String?

    public init(
        title: String,
        markdownContent: String,
        baseVersionId: String?
    ) {
        self.title = title
        self.markdownContent = markdownContent
        self.baseVersionId = baseVersionId
    }
}

public struct DevelopmentRecordCreateRequest: Encodable {
    public let draft: DevelopmentRecordDraftRequest

    public init(draft: DevelopmentRecordDraftRequest) {
        self.draft = draft
    }
}

public struct DevelopmentRecordConfirmationRequest {
    public let versionId: String
    public let kind: String
    public let sourceVersionId: String?

    public init(
        versionId: String,
        kind: String,
        sourceVersionId: String?
    ) {
        self.versionId = versionId
        self.kind = kind
        self.sourceVersionId = sourceVersionId
    }
}

public struct DevelopmentRecordRestoreRequest {
    public let versionId: String
    public let sourceVersionId: String

    public init(versionId: String, sourceVersionId: String) {
        self.versionId = versionId
        self.sourceVersionId = sourceVersionId
    }
}

public struct DevelopmentRecordDraftResponse {
    public let title: String
    public let markdownContent: String
    public let baseVersionId: String?
    public let updatedAt: Date

    public init(
        title: String,
        markdownContent: String,
        baseVersionId: String?,
        updatedAt: Date
    ) {
        self.title = title
        self.markdownContent = markdownContent
        self.baseVersionId = baseVersionId
        self.updatedAt = updatedAt
    }
}

public struct DevelopmentRecordCurrentVersionResponse {
    public let id: String
    public let number: Int

    public init(id: String, number: Int) {
        self.id = id
        self.number = number
    }
}

public struct DevelopmentRecordResponse {
    public let id: String
    public let goalId: String
    public let currentVersion: DevelopmentRecordCurrentVersionResponse?
    public let draft: DevelopmentRecordDraftResponse?
    public let createdAt: Date

    public init(
        id: String,
        goalId: String,
        currentVersion: DevelopmentRecordCurrentVersionResponse?,
        draft: DevelopmentRecordDraftResponse?,
        createdAt: Date
    ) {
        self.id = id
        self.goalId = goalId
        self.currentVersion = currentVersion
        self.draft = draft
        self.createdAt = createdAt
    }
}

public struct DevelopmentRecordVersionResponse {
    public let id: String
    public let recordId: String
    public let number: Int
    public let title: String
    public let markdownContent: String
    public let kind: String
    public let sourceVersionId: String?
    public let confirmedAt: Date

    public init(
        id: String,
        recordId: String,
        number: Int,
        title: String,
        markdownContent: String,
        kind: String,
        sourceVersionId: String?,
        confirmedAt: Date
    ) {
        self.id = id
        self.recordId = recordId
        self.number = number
        self.title = title
        self.markdownContent = markdownContent
        self.kind = kind
        self.sourceVersionId = sourceVersionId
        self.confirmedAt = confirmedAt
    }
}
