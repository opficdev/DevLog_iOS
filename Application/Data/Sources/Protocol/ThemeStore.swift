//
//  ThemeStore.swift
//  Data
//
//  Created by opfic on 5/14/26.
//

import Combine
import Foundation
import Core

public protocol ThemeStore {
    func observeTheme() -> AnyPublisher<SystemTheme, Never>
    func send(_ theme: SystemTheme)
}
