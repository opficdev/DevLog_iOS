//
//  FetchDailyActivityEventsUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 4/4/26.
//

final class FetchDailyActivityEventsUseCaseImpl: FetchDailyActivityEventsUseCase {
    private let repository: DailyActivityRepository

    init(_ repository: DailyActivityRepository) {
        self.repository = repository
    }

    func execute(dayKey: String) async throws -> [DailyActivityEvent] {
        try await repository.fetchActivityEvents(dayKey: dayKey)
    }
}
