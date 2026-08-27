//
//  DevelopmentRecord.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

import Foundation

public struct DevelopmentRecord: Hashable {
    public struct Draft: Hashable {
        public let title: String
        public let markdownContent: String
        public let baseVersionID: String?
        public let updatedAt: Date

        public init(
            title: String,
            markdownContent: String,
            baseVersionID: String?,
            updatedAt: Date
        ) throws {
            guard title.containsMeaningfulCharacter else {
                throw DomainLayerError.invalidDevelopmentRecordTitle
            }
            guard baseVersionID?.containsMeaningfulCharacter != false else {
                throw DomainLayerError.invalidDevelopmentRecordVersion
            }

            self.title = title
            self.markdownContent = markdownContent
            self.baseVersionID = baseVersionID
            self.updatedAt = updatedAt
        }
    }

    public struct CurrentVersion: Hashable {
        public let id: String
        public let number: Int

        public init(id: String, number: Int) throws {
            guard id.containsMeaningfulCharacter, 0 < number else {
                throw DomainLayerError.invalidDevelopmentRecordCurrentVersion
            }

            self.id = id
            self.number = number
        }
    }

    public struct Version: Hashable {
        public enum Kind: Hashable {
            case initial
            case correction
            case rollback
        }

        public let id: String
        public let recordID: String
        public let number: Int
        public let title: String
        public let markdownContent: String
        public let kind: Kind
        public let sourceVersionID: String?
        public let confirmedAt: Date

        public init(
            id: String,
            recordID: String,
            number: Int,
            title: String,
            markdownContent: String,
            kind: Kind,
            sourceVersionID: String?,
            confirmedAt: Date
        ) throws {
            guard id.containsMeaningfulCharacter,
                  recordID.containsMeaningfulCharacter,
                  title.containsMeaningfulCharacter,
                  0 < number else {
                throw DomainLayerError.invalidDevelopmentRecordVersion
            }

            switch kind {
            case .initial:
                guard number == 1, sourceVersionID == nil else {
                    throw DomainLayerError.invalidDevelopmentRecordVersion
                }
            case .correction, .rollback:
                guard 1 < number,
                      let sourceVersionID,
                      sourceVersionID.containsMeaningfulCharacter,
                      sourceVersionID != id else {
                    throw DomainLayerError.invalidDevelopmentRecordVersion
                }
            }

            self.id = id
            self.recordID = recordID
            self.number = number
            self.title = title
            self.markdownContent = markdownContent
            self.kind = kind
            self.sourceVersionID = sourceVersionID
            self.confirmedAt = confirmedAt
        }
    }

    public let id: String
    public let goalID: String
    public let currentVersion: CurrentVersion?
    public let draft: Draft?
    public let createdAt: Date

    public init(
        id: String,
        goalID: String,
        currentVersion: CurrentVersion?,
        draft: Draft?,
        createdAt: Date
    ) throws {
        guard id.containsMeaningfulCharacter, goalID.containsMeaningfulCharacter else {
            throw DomainLayerError.invalidData(context: "developmentRecord")
        }
        guard currentVersion != nil || draft != nil else {
            throw DomainLayerError.invalidDevelopmentRecordCurrentVersion
        }

        if let currentVersion, let draft {
            guard draft.baseVersionID == currentVersion.id else {
                throw DomainLayerError.invalidDevelopmentRecordCurrentVersion
            }
        } else if currentVersion == nil {
            guard draft?.baseVersionID == nil else {
                throw DomainLayerError.invalidDevelopmentRecordCurrentVersion
            }
        }

        self.id = id
        self.goalID = goalID
        self.currentVersion = currentVersion
        self.draft = draft
        self.createdAt = createdAt
    }
}

private extension String {
    var containsMeaningfulCharacter: Bool {
        !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
