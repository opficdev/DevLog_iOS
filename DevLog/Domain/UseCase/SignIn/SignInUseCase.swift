//
//  SignInUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 11/2/25.
//

protocol SignInUseCase {
    var repository: AuthenticationRepository { get }
    func execute() async throws -> AuthenticationData
}
