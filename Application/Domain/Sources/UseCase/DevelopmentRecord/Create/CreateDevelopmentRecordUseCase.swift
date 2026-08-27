//
//  CreateDevelopmentRecordUseCase.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol CreateDevelopmentRecordUseCase {
    func execute(
        goalID: String,
        title: String,
        markdownContent: String
    ) async throws -> DevelopmentRecord
}
