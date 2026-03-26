//
//  UserPreferencesRepository.swift
//  DevLog
//
//  Created by 최윤진 on 2/25/26.
//

import Foundation
import Combine

protocol UserPreferencesRepository {
    func observeSystemTheme() -> AnyPublisher<SystemTheme, Never>
    func systemTheme() -> SystemTheme
    func setSystemTheme(_ theme: SystemTheme)

    func recentSearchQueries() -> [String]
    func setRecentSearchQueries(_ queries: [String])

    func pushNotificationSortOrder() -> PushNotificationQuery.SortOrder
    func setPushNotificationSortOrder(_ order: PushNotificationQuery.SortOrder)

    func pushNotificationTimeFilter() -> PushNotificationQuery.TimeFilter
    func setPushNotificationTimeFilter(_ filter: PushNotificationQuery.TimeFilter)

    func pushNotificationUnreadOnly() -> Bool
    func setPushNotificationUnreadOnly(_ value: Bool)

    func profileHeatmapActivityTypes() -> [String]
    func setProfileHeatmapActivityTypes(_ activityTypes: [String])

    func todayDisplayOptions() -> TodayDisplayOptions
    func setTodayDisplayOptions(_ options: TodayDisplayOptions)
}
