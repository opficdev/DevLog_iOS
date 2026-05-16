//
//  UpdateTodayDisplayOptionsUseCaseImpl.swift
//  DevLogDomain
//
//  Created by opfic on 3/6/26.
//

public final class UpdateTodayDisplayOptionsUseCaseImpl: UpdateTodayDisplayOptionsUseCase {
    private let repository: UserPreferencesRepository

    init(_ repository: UserPreferencesRepository) {
        self.repository = repository
    }

    public func execute(_ options: TodayDisplayOptions) {
        repository.setTodayDisplayOptions(options)
    }
}
