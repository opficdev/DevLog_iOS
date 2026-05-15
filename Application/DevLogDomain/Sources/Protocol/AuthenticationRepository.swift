//
//  AuthenticationRepository.swift
//  DevLog
//
//  Created by 최윤진 on 11/14/25.
//

import Foundation

public protocol AuthenticationRepository {
    func signIn(_ provider: AuthProvider) async throws
    func signOut() async throws
    func restore() -> Bool
    func delete() async throws
}
