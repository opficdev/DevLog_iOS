//
//  NetworkConnectivityRepositoryImpl.swift
//  DevLog
//
//  Created by opfic on 3/26/26.
//

import Combine
import DevLogDomain
import DevLogDataCommon
import DevLogDataDTO
import DevLogDataMapper
import DevLogDataProtocol

final class NetworkConnectivityRepositoryImpl: NetworkConnectivityRepository {
    private let connectivityProvider: NWPathConnectivityProvider

    init(connectivityProvider: NWPathConnectivityProvider) {
        self.connectivityProvider = connectivityProvider
    }

    func observeNetworkConnectivity() -> AnyPublisher<Bool, Never> {
        connectivityProvider.observeNetworkConnectivity()
    }
}
