//
//  NetworkRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 10/9/25.
//

import Foundation
import Network

final class NetworkRepositoryImpl: NetworkRepository {
    private let networkPathMonitor = NWPathMonitor()
    private let networkMonitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        let initialIsConnected = networkPathMonitor.currentPath.status == .satisfied
        
        networkPathMonitor.pathUpdateHandler = { [weak self] path in
            let isConnected = (path.status == .satisfied)
            DispatchQueue.main.async {

            }
        }
        
        networkPathMonitor.start(queue: networkMonitorQueue)
    }
    
    deinit {
        networkPathMonitor.cancel()
    }
}
