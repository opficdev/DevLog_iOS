//
//  AuthenticationRepository.swift
//  Domain
//
//  Created by 최윤진 on 11/14/25.
//

import Foundation

public protocol AuthenticationRepository {
    func signIn(_ provider: AuthProvider) async throws -> Bool
    func signOut() async throws
    func delete() async throws
}
