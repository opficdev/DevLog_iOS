//
//  DailyActivityRepository.swift
//  DevLog
//
//  Created by opfic on 4/4/26.
//

protocol DailyActivityRepository {
    func fetchActivities(
        from startDayKey: String,
        to endDayKey: String
    ) async throws -> [DailyActivity]

    func fetchActivityEvents(dayKey: String) async throws -> [DailyActivityEvent]
}
