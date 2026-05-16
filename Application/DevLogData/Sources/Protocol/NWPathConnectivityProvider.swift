//
//  NWPathConnectivityProvider.swift
//  DevLogData
//
//  Created by opfic on 5/14/26.
//

import Combine
import Foundation

public protocol NWPathConnectivityProvider {
    func observeNetworkConnectivity() -> AnyPublisher<Bool, Never>
}
