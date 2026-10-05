//
//  FetchRecentDevelopmentRecordUseCase.swift
//  Domain
//
//  Created by opfic on 10/5/26.
//

public protocol FetchRecentDevelopmentRecordUseCase {
    func execute(goalId: String) async throws -> DevelopmentRecord.Version?
}
