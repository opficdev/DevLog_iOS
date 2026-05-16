//
//  ObserveSystemThemeUseCase.swift
//  DevLogDomain
//
//  Created by 최윤진 on 2/25/26.
//

import Combine

public protocol ObserveSystemThemeUseCase {
    func observe() -> AnyPublisher<SystemTheme, Never>
}
