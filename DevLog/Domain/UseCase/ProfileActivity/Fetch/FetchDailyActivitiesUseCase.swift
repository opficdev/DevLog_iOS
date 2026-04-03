//
//  FetchDailyActivitiesUseCase.swift
//  DevLog
//
//  Created by opfic on 4/4/26.
//

protocol FetchDailyActivitiesUseCase {
    func execute(
        from startDayKey: String,
        to endDayKey: String
    ) async throws -> [DailyActivity]
}
