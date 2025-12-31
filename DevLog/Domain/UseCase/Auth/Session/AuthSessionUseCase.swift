//
//  AuthSessionUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 12/31/25.
//

protocol AuthSessionUseCase {
    var repository: AuthSessionRepository { get }
    func execute(_ signIn: Bool)
}
