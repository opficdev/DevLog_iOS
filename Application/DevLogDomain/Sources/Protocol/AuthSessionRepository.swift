//
//  AuthSessionRepository.swift
//  DevLogDomain
//
//  Created by 최윤진 on 12/30/25.
//

import Combine

public protocol AuthSessionRepository {
    func observeSignedIn() -> AnyPublisher<Bool, Never>
}
