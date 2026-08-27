//
//  RestoreDevelopmentRecordUseCase.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol RestoreDevelopmentRecordUseCase {
    func execute(
        goalID: String,
        recordID: String,
        sourceVersionID: String
    ) async throws -> DevelopmentRecord.Version
}
