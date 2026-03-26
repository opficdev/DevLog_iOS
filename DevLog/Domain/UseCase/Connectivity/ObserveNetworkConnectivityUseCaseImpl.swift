//
//  ObserveNetworkConnectivityUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 3/26/26.
//

import Combine

final class ObserveNetworkConnectivityUseCaseImpl: ObserveNetworkConnectivityUseCase {
    private let repository: NetworkConnectivityRepository

    init(_ repository: NetworkConnectivityRepository) {
        self.repository = repository
    }

    var publisher: AnyPublisher<Bool, Never> {
        repository.observeNetworkConnectivity()
    }
}
