//
//  SignOutUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 12/14/25.
//

protocol SignOutUseCase {
    var repository: AuthenticationRepository { get }
    func execute(_ provider: AuthProvider) async throws
}
