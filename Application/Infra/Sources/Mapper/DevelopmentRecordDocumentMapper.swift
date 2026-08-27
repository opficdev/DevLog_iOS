//
//  DevelopmentRecordDocumentMapper.swift
//  Infra
//
//  Created by opfic on 8/28/26.
//

import FirebaseFirestore
import Data

struct DevelopmentRecordDocumentMapper {
    func map(
        goalId: String,
        documentId: String,
        data: [String: Any]
    ) -> DevelopmentRecordResponse? {
        guard let createdAt = data[DevelopmentRecordFieldKey.createdAt.rawValue] as? Timestamp else {
            return nil
        }

        let currentVersion: DevelopmentRecordCurrentVersionResponse?
        let currentVersionId = data[DevelopmentRecordFieldKey.currentVersionId.rawValue] as? String
        let currentVersionNumber = data[DevelopmentRecordFieldKey.currentVersionNumber.rawValue] as? Int
        switch (currentVersionId, currentVersionNumber) {
        case let (.some(id), .some(number)):
            currentVersion = .init(id: id, number: number)
        case (nil, nil):
            currentVersion = nil
        default:
            return nil
        }

        let draft: DevelopmentRecordDraftResponse?
        if let data = data[DevelopmentRecordFieldKey.draft.rawValue] as? [String: Any] {
            guard
                let title = data[DevelopmentRecordDraftFieldKey.title.rawValue] as? String,
                let markdownContent = data[DevelopmentRecordDraftFieldKey.markdownContent.rawValue] as? String,
                let updatedAt = data[DevelopmentRecordDraftFieldKey.updatedAt.rawValue] as? Timestamp else {
                return nil
            }
            draft = .init(
                title: title,
                markdownContent: markdownContent,
                baseVersionId: data[DevelopmentRecordDraftFieldKey.baseVersionId.rawValue] as? String,
                updatedAt: updatedAt.dateValue()
            )
        } else {
            draft = nil
        }

        return DevelopmentRecordResponse(
            id: documentId,
            goalId: goalId,
            currentVersion: currentVersion,
            draft: draft,
            createdAt: createdAt.dateValue()
        )
    }

    func mapVersion(
        recordId: String,
        documentId: String,
        data: [String: Any]
    ) -> DevelopmentRecordVersionResponse? {
        guard
            let number = data[DevelopmentRecordVersionFieldKey.versionNumber.rawValue] as? Int,
            let title = data[DevelopmentRecordVersionFieldKey.title.rawValue] as? String,
            let markdownContent = data[DevelopmentRecordVersionFieldKey.markdownContent.rawValue] as? String,
            let kind = data[DevelopmentRecordVersionFieldKey.changeKind.rawValue] as? String,
            let confirmedAt = data[DevelopmentRecordVersionFieldKey.confirmedAt.rawValue] as? Timestamp else {
            return nil
        }
        return DevelopmentRecordVersionResponse(
            id: documentId,
            recordId: recordId,
            number: number,
            title: title,
            markdownContent: markdownContent,
            kind: kind,
            sourceVersionId: data[DevelopmentRecordVersionFieldKey.sourceVersionId.rawValue] as? String,
            confirmedAt: confirmedAt.dateValue()
        )
    }
}

enum DevelopmentRecordFieldKey: String {
    case currentVersionId
    case currentVersionNumber
    case draft
    case createdAt
}

enum DevelopmentRecordDraftFieldKey: String {
    case title
    case markdownContent
    case baseVersionId
    case updatedAt
}

enum DevelopmentRecordVersionFieldKey: String {
    case versionNumber
    case title
    case markdownContent
    case changeKind
    case sourceVersionId
    case confirmedAt
}
