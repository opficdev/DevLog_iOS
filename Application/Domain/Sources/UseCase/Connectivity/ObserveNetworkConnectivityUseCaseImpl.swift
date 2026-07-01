//
//  ObserveNetworkConnectivityUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 3/26/26.
//

import Combine

public final class ObserveNetworkConnectivityUseCaseImpl: ObserveNetworkConnectivityUseCase {
    private let repository: NetworkConnectivityRepository

    init(_ repository: NetworkConnectivityRepository) {
        self.repository = repository
    }

    public func observe() -> AnyPublisher<Bool, Never> {
        repository.observeNetworkConnectivity()
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
