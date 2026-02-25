//
//  FetchSystemThemeUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 2/25/26.
//

import Combine

protocol FetchSystemThemeUseCase {
    var publisher: AnyPublisher<SystemTheme, Never> { get }
}
