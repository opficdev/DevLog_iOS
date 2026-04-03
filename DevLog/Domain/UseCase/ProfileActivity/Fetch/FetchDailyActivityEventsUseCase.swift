//
//  FetchDailyActivityEventsUseCase.swift
//  DevLog
//
//  Created by opfic on 4/4/26.
//

protocol FetchDailyActivityEventsUseCase {
    func execute(dayKey: String) async throws -> [DailyActivityEvent]
}
