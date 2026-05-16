//
//  ObserveSystemThemeUseCase.swift
//  DevLogDomain
//
//  Created by 최윤진 on 2/25/26.
//

import Combine
import DevLogCore

public protocol ObserveSystemThemeUseCase {
    func observe() -> AnyPublisher<SystemTheme, Never>
}
