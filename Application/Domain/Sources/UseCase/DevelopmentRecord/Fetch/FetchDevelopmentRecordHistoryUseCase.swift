//
//  FetchDevelopmentRecordHistoryUseCase.swift
//  Domain
//
//  Created by opfic on 8/27/26.
//

public protocol FetchDevelopmentRecordHistoryUseCase {
    func execute(goalID: String, recordID: String) async throws -> [DevelopmentRecord.Version]
}
