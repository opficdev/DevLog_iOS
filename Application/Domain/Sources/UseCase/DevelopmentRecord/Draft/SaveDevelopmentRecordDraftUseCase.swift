//
//  SaveDevelopmentRecordDraftUseCase.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol SaveDevelopmentRecordDraftUseCase {
    func execute(
        goalId: String,
        recordId: String,
        title: String,
        markdownContent: String
    ) async throws -> DevelopmentRecord
}
