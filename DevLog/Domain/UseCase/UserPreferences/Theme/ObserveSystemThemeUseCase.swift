//
//  ObserveSystemThemeUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 2/25/26.
//

import Combine

protocol ObserveSystemThemeUseCase {
    var publisher: AnyPublisher<SystemTheme, Never> { get }
}
