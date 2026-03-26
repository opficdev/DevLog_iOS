//
//  ObserveAuthSessionUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 12/31/25.
//

import Combine

final class ObserveAuthSessionUseCaseImpl: ObserveAuthSessionUseCase {
    private let repository: AuthSessionRepository

    var signedInPublisher: AnyPublisher<Bool, Never> {
        repository.signedInPublisher
    }

    init(_ repository: AuthSessionRepository) {
        self.repository = repository
    }
}
