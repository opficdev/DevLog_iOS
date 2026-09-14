//
//  ConfirmDevelopmentRecordUseCase.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol ConfirmDevelopmentRecordUseCase {
    func execute(
        goalId: String,
        recordId: String,
        versionId: String,
        baseVersionId: String?,
        draftRevisionId: String?
    ) async throws -> DevelopmentRecord.Version
}
