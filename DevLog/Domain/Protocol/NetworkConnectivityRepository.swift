//
//  NetworkConnectivityRepository.swift
//  DevLog
//
//  Created by opfic on 3/26/26.
//

import Combine

protocol NetworkConnectivityRepository {
    func observeNetworkConnectivity() -> AnyPublisher<Bool, Never>
}
