//
//  DomainLayerError.swift
//  Domain
//
//  Created by opfic on 7/10/26.
//

public enum DomainLayerError: Error, Equatable {
    case invalidData(context: String)
    case invalidDevelopmentGoalTitle
    case invalidDevelopmentRecordTitle
    case invalidDevelopmentGoalTransition
    case developmentGoalIsNotInProgress
    case developmentGoalCompletionRequiresRecord
    case developmentGoalCompletionNeedsVersion
    case developmentGoalCompletionHasDraft
    case invalidDevelopmentRecordCurrentVersion
    case developmentRecordDraftNotFound
    case developmentRecordDraftConflict
    case invalidDevelopmentRecordVersion
    case developmentRecordVersionNotFound
}
