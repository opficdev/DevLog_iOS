//
//  UpdateSystemThemeUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/25/26.
//

public final class UpdateSystemThemeUseCaseImpl: UpdateSystemThemeUseCase {
    private let repository: UserPreferencesRepository

    init(_ repository: UserPreferencesRepository) {
        self.repository = repository
    }

    public func execute(_ theme: SystemTheme) {
        repository.setSystemTheme(theme)
    }
}
