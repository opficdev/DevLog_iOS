//
//  CreateDevelopmentRecordUseCase.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol CreateDevelopmentRecordUseCase {
    func execute(
        goalId: String,
        title: String,
        markdownContent: String
    ) async throws -> DevelopmentRecord
}
