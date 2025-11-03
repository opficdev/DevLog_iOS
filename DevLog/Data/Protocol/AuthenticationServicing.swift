//
//  AuthenticationServicing.swift
//  DevLog
//
//  Created by 최윤진 on 11/3/25.
//

import Foundation

protocol AuthenticationServicing {
    func signIn() async throws -> AuthenticationData
    func signOut(_ uid: String) async throws
    func deleteAuth(_ uid: String) async throws
}
