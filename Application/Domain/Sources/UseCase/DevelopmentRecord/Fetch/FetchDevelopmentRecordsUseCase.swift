//
//  FetchDevelopmentRecordsUseCase.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol FetchDevelopmentRecordsUseCase {
    func execute(goalID: String) async throws -> [DevelopmentRecord]
}
