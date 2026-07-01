//
//  NetworkConnectivityRepository.swift
//  Domain
//
//  Created by opfic on 3/26/26.
//

import Combine

public protocol NetworkConnectivityRepository {
    func observeNetworkConnectivity() -> AnyPublisher<Bool, Never>
}
