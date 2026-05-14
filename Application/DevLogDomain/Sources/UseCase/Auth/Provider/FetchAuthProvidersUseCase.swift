//
//  FetchAuthProvidersUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 2/12/26.
//

public protocol FetchAuthProvidersUseCase {
    func execute() async throws -> (currentProvider: AuthProvider?, allProviders: [AuthProvider])
}
