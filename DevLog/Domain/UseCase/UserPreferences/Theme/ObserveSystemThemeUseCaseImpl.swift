//
//  ObserveSystemThemeUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/25/26.
//

import Combine

final class ObserveSystemThemeUseCaseImpl: ObserveSystemThemeUseCase {
    private let repository: UserPreferencesRepository

    init(_ repository: UserPreferencesRepository) {
        self.repository = repository
    }

    var publisher: AnyPublisher<SystemTheme, Never> {
        repository.observeSystemTheme()
    }
}
