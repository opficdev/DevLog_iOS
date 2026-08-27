//
//  FetchDevelopmentRecordsUseCase.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol FetchDevelopmentRecordsUseCase {
    func execute(goalId: String) async throws -> [DevelopmentRecord]
}
