//
//  SaveDevelopmentRecordDraftUseCase.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol SaveDevelopmentRecordDraftUseCase {
    func execute(
        goalID: String,
        recordID: String,
        title: String,
        markdownContent: String
    ) async throws -> DevelopmentRecord
}
