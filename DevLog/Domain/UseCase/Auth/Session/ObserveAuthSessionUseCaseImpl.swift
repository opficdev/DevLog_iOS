//
//  ObserveAuthSessionUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 12/31/25.
//

import Combine

final class ObserveAuthSessionUseCaseImpl: ObserveAuthSessionUseCase {
    private let repository: AuthSessionRepository

    func observe() -> AnyPublisher<Bool, Never> {
        repository.observeSignedIn()
    }

    init(_ repository: AuthSessionRepository) {
        self.repository = repository
    }
}
