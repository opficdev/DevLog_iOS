//
//  UpdateFirstLaunchUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/25/26.
//

final class UpdateFirstLaunchUseCaseImpl: UpdateFirstLaunchUseCase {
    private let repository: UserPreferencesRepository

    init(_ repository: UserPreferencesRepository) {
        self.repository = repository
    }

    func execute(_ value: Bool) {
        repository.setFirstLaunch(value)
    }
}
