//
//  ObserveNetworkConnectivityUseCase.swift
//  DevLog
//
//  Created by opfic on 3/26/26.
//

import Combine

protocol ObserveNetworkConnectivityUseCase {
    var publisher: AnyPublisher<Bool, Never> { get }
}
