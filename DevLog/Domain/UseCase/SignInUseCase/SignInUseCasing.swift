//
//  SignInUseCasing.swift
//  DevLog
//
//  Created by 최윤진 on 11/2/25.
//

import Foundation

protocol SignInUseCasing {
    var repository: AuthenticationRepository { get }
    func execute() async throws -> AuthenticationData
}
