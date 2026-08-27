//
//  RestoreDevelopmentRecordUseCase.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol RestoreDevelopmentRecordUseCase {
    func execute(
        goalId: String,
        recordId: String,
        sourceVersionId: String
    ) async throws -> DevelopmentRecord.Version
}
