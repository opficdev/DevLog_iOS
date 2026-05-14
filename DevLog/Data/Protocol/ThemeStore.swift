//
//  ThemeStore.swift
//  DevLog
//
//  Created by opfic on 5/14/26.
//

import Combine
import Foundation
import DevLogDomain
import DevLogDataDTO

public protocol ThemeStore {
    func observeTheme() -> AnyPublisher<SystemTheme, Never>
    func send(_ theme: SystemTheme)
}
