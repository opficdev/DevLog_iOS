//
//  NetworkConnectivityRepositoryImpl.swift
//  DevLog
//
//  Created by opfic on 3/26/26.
//

import Combine

final class NetworkConnectivityRepositoryImpl: NetworkConnectivityRepository {
    private let connectivityProvider: NWPathConnectivityProvider

    init(connectivityProvider: NWPathConnectivityProvider) {
        self.connectivityProvider = connectivityProvider
    }

    var publisher: AnyPublisher<Bool, Never> {
        connectivityProvider.isConnectedPublisher
    }
}
