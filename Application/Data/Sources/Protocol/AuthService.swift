//
//  AuthService.swift
//  Data
//
//  Created by opfic on 5/14/26.
//

import Combine
import Foundation

public protocol AuthService {
    var uid: String? { get }
    var providerIDs: [String] { get }
    var providerCount: Int { get }

    func observeSignedIn() -> AnyPublisher<Bool, Never>
    func beginSignIn()
    func completeSignIn()
    func cancelSignIn()
    func getProviderID() async throws -> String?
    func deleteCurrentUser() async throws
    func clearCurrentSession() async throws
}
