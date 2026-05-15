//
//  AuthService.swift
//  DevLog
//
//  Created by opfic on 5/14/26.
//

import Combine
import Foundation
import DevLogDataDTO

public protocol AuthService {
    var uid: String? { get }
    var providerIDs: [String] { get }
    var currentUserEmail: String? { get }
    var providerCount: Int { get }

    func observeSignedIn() -> AnyPublisher<Bool, Never>
    func beginSignIn()
    func completeSignIn()
    func cancelSignIn()
    func getProviderID() async throws -> String?
    func deleteCurrentUser() async throws
    func clearCurrentSession() async throws
    func isCredentialAlreadyInUseError(_ error: Error) -> Bool
}
