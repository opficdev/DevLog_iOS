//
//  AuthSessionStateProvider.swift
//  Data
//
//  Created by opfic on 6/9/26.
//

import Combine

public protocol AuthSessionStateProvider {
    func publish(_ isSignedIn: Bool)
    func observeSignedIn() -> AnyPublisher<Bool, Never>
}
