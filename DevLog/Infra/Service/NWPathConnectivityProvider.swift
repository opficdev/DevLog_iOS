//
//  NWPathConnectivityProvider.swift
//  DevLog
//
//  Created by 최윤진 on 11/2/25.
//

import Foundation
import Network

final class NWPathConnectivityProvider {
    private let networkPathMonitor = NWPathMonitor()
    private let monitoringQueue = DispatchQueue(label: "NWPathConnectivityProviderQueue")

    private var isConnectedValue: Bool
    private var connectivityContinuations: [UUID: AsyncStream<Bool>.Continuation] = [:]

    init() {
        self.isConnectedValue = (networkPathMonitor.currentPath.status == .satisfied)

        self.networkPathMonitor.pathUpdateHandler = { [weak self] path in
            let connected = (path.status == .satisfied)
            Task { @MainActor in
                self?.handlePathStatusChange(isConnected: connected)
            }
        }
        self.networkPathMonitor.start(queue: monitoringQueue)
    }

    deinit {
        self.networkPathMonitor.cancel()
        self.connectivityContinuations.values.forEach { $0.finish() }
        self.connectivityContinuations.removeAll()
    }

    var isConnected: Bool {
        self.isConnectedValue
    }

    func connectivityStream() -> AsyncStream<Bool> {
        let identifier = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { [weak self] continuation in
            guard let self else { return }
            self.connectivityContinuations[identifier] = continuation
            continuation.yield(self.isConnectedValue)

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.connectivityContinuations.removeValue(forKey: identifier)
                }
            }
        }
    }

    private func handlePathStatusChange(isConnected: Bool) {
        guard isConnected != self.isConnectedValue else { return }
        self.isConnectedValue = isConnected
        for continuation in self.connectivityContinuations.values {
            continuation.yield(isConnected)
        }
    }
}
