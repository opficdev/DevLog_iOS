//
//  ObserveSystemThemeUseCase.swift
//  Domain
//
//  Created by 최윤진 on 2/25/26.
//

import Combine
import Core

public protocol ObserveSystemThemeUseCase {
    func observe() -> AnyPublisher<SystemTheme, Never>
}
