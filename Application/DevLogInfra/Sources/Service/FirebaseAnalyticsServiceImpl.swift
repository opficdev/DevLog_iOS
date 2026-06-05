//
//  FirebaseAnalyticsServiceImpl.swift
//  DevLogInfra
//
//  Created by opfic on 5/27/26.
//

import DevLogData
import FirebaseAnalytics

final class FirebaseAnalyticsServiceImpl: AnalyticsService {
    private enum EventName {
        static let todoCreate = "todo_create"
        static let todoComplete = "todo_complete"
        static let webPageCreate = "webpage_create"
        static let pushOpen = "push_open"
    }

    func trackScreenView(_ name: String) {
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: name
            ]
        )
    }

    func trackTodoCreate() {
        Analytics.logEvent(EventName.todoCreate, parameters: nil)
    }

    func trackTodoComplete() {
        Analytics.logEvent(EventName.todoComplete, parameters: nil)
    }

    func trackWebPageCreate() {
        Analytics.logEvent(EventName.webPageCreate, parameters: nil)
    }

    func trackPushOpen() {
        Analytics.logEvent(EventName.pushOpen, parameters: nil)
    }
}
