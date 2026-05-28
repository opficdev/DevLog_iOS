//
//  AnalyticsRepositoryImpl.swift
//  DevLogData
//
//  Created by opfic on 5/27/26.
//

import DevLogDomain

final class AnalyticsRepositoryImpl: AnalyticsRepository {
    private let analyticsService: AnalyticsService

    init(analyticsService: AnalyticsService) {
        self.analyticsService = analyticsService
    }

    func track(_ event: AnalyticsEvent) {
        switch event {
        case .screenView(let name):
            analyticsService.trackScreenView(name)
        case .todoCreate:
            analyticsService.trackTodoCreate()
        case .todoComplete:
            analyticsService.trackTodoComplete()
        case .webPageCreate:
            analyticsService.trackWebPageCreate()
        case .pushOpen:
            analyticsService.trackPushOpen()
        }
    }
}
