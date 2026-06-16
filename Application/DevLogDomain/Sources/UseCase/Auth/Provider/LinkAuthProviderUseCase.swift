//
//  LinkAuthProviderUseCase.swift
//  DevLogDomain
//
//  Created by 최윤진 on 2/12/26.
//

public protocol LinkAuthProviderUseCase {
    func execute(_ provider: AuthProvider) async throws -> Bool
}
