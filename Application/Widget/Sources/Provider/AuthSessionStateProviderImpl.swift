//
//  AuthSessionStateProviderImpl.swift
//  Widget
//
//  Created by opfic on 6/9/26.
//

import Combine
import Data

public final class AuthSessionStateProviderImpl: AuthSessionStateProvider {
    private let subject = CurrentValueSubject<Bool?, Never>(nil)

    public init() { }

    public func publish(_ isSignedIn: Bool) {
        subject.send(isSignedIn)
    }

    public func observeSignedIn() -> AnyPublisher<Bool, Never> {
        subject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}
