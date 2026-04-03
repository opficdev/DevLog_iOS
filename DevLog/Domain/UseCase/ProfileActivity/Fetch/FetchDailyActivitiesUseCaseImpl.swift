//
//  FetchDailyActivitiesUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 4/4/26.
//

final class FetchDailyActivitiesUseCaseImpl: FetchDailyActivitiesUseCase {
    private let repository: DailyActivityRepository

    init(_ repository: DailyActivityRepository) {
        self.repository = repository
    }

    func execute(
        from startDayKey: String,
        to endDayKey: String
    ) async throws -> [DailyActivity] {
        try await repository.fetchActivities(
            from: startDayKey,
            to: endDayKey
        )
    }
}
