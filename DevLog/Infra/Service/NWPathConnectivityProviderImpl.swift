//
//  NWPathConnectivityProviderImpl.swift
//  DevLog
//
//  Created by 최윤진 on 11/2/25.
//

import Network
import Combine

final class NWPathConnectivityProviderImpl: NWPathConnectivityProvider {
    private let networkPathMonitor = NWPathMonitor()
    private let monitoringQueue = DispatchQueue(label: "NWPathConnectivityProviderQueue")
    private let isConnectedSubject = CurrentValueSubject<Bool?, Never>(nil)

    init() {
        networkPathMonitor.pathUpdateHandler = { [weak self] path in
            let connected = (path.status == .satisfied)
            self?.isConnectedSubject.send(connected)
        }
        networkPathMonitor.start(queue: monitoringQueue)
    }

    deinit {
        networkPathMonitor.cancel()
        isConnectedSubject.send(completion: .finished)
    }

    func observeNetworkConnectivity() -> AnyPublisher<Bool, Never> {
        isConnectedSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}
