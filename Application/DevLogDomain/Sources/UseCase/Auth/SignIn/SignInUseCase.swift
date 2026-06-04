//
//  SignInUseCase.swift
//  DevLogDomain
//
//  Created by 최윤진 on 11/2/25.
//

public protocol SignInUseCase: Sendable {
    func execute(_ provider: AuthProvider) async throws
}
