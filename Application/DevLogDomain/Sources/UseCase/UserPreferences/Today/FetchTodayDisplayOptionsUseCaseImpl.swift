//
//  FetchTodayDisplayOptionsUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 3/6/26.
//

public final class FetchTodayDisplayOptionsUseCaseImpl: FetchTodayDisplayOptionsUseCase {
    private let repository: UserPreferencesRepository

    init(_ repository: UserPreferencesRepository) {
        self.repository = repository
    }

    public func execute() -> TodayDisplayOptions {
        repository.todayDisplayOptions()
    }
}
