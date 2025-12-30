//
//  RestoreAuthUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 12/30/25.
//

protocol RestoreAuthUseCase {
    var repository: AuthenticationRepository { get }
    func execute() -> Bool
}
