//
//  SignInUseCase.swift
//  Domain
//
//  Created by 최윤진 on 11/2/25.
//

public protocol SignInUseCase {
    func execute(_ provider: AuthProvider) async throws -> Bool
}
