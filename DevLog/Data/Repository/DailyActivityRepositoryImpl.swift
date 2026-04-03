//
//  DailyActivityRepositoryImpl.swift
//  DevLog
//
//  Created by opfic on 4/4/26.
//

final class DailyActivityRepositoryImpl: DailyActivityRepository {
    private let dailyActivityService: DailyActivityService

    init(dailyActivityService: DailyActivityService) {
        self.dailyActivityService = dailyActivityService
    }

    func fetchActivities(
        from startDayKey: String,
        to endDayKey: String
    ) async throws -> [DailyActivity] {
        let dailyActivityResponses = try await dailyActivityService.fetchActivities(
            from: startDayKey,
            to: endDayKey
        )

        return dailyActivityResponses.map { $0.toDomain() }
    }

    func fetchActivityEvents(dayKey: String) async throws -> [DailyActivityEvent] {
        let dailyActivityEventResponses = try await dailyActivityService.fetchActivityEvents(dayKey: dayKey)
        return try dailyActivityEventResponses.map { try $0.toDomain() }
    }
}
