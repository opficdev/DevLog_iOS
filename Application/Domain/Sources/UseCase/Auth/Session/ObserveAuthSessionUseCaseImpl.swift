//
//  ObserveAuthSessionUseCaseImpl.swift
//  Domain
//
//  Created by 최윤진 on 12/31/25.
//

import Combine

public final class ObserveAuthSessionUseCaseImpl: ObserveAuthSessionUseCase {
    private let repository: AuthSessionRepository

    init(_ repository: AuthSessionRepository) {
        self.repository = repository
    }

    public func observe() -> AnyPublisher<Bool, Never> {
        repository.observeSignedIn()
    }
}
