//
//  SignInServicing.swift
//  DevLog
//
//  Created by 최윤진 on 11/2/25.
//

import Foundation

protocol SignInServicing {
    func signIn() async throws -> AuthenticationData
}
