//
//  FetchTodayDisplayOptionsUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 3/6/26.
//

final class FetchTodayDisplayOptionsUseCaseImpl: FetchTodayDisplayOptionsUseCase {
    private let repository: UserPreferencesRepository

    init(_ repository: UserPreferencesRepository) {
        self.repository = repository
    }

    func execute() -> TodayDisplayOptions {
        repository.todayDisplayOptions()
    }
}
