//
//  AuthenticationRepository.swift
//  DevLog
//
//  Created by 최윤진 on 11/14/25.
//

import Foundation

protocol AuthenticationRepository {
    func signInWithApple() async throws -> AuthenticationData
    func signInWithGithub() async throws -> AuthenticationData
    func signInWithGoogle() async throws -> AuthenticationData
}
