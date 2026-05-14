//
//  NWPathConnectivityProvider.swift
//  DevLog
//
//  Created by opfic on 5/14/26.
//

import Combine
import Foundation

protocol NWPathConnectivityProvider {
    func observeNetworkConnectivity() -> AnyPublisher<Bool, Never>
}
