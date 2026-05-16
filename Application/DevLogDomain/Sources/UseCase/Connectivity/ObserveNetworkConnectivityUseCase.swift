//
//  ObserveNetworkConnectivityUseCase.swift
//  DevLogDomain
//
//  Created by opfic on 3/26/26.
//

import Combine

public protocol ObserveNetworkConnectivityUseCase {
    func observe() -> AnyPublisher<Bool, Never>
}
