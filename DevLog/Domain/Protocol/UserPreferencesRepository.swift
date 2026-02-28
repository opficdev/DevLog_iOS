//
//  UserPreferencesRepository.swift
//  DevLog
//
//  Created by 최윤진 on 2/25/26.
//

import Foundation
import Combine

protocol UserPreferencesRepository {
    var systemThemePublisher: AnyPublisher<SystemTheme, Never> { get }
    func systemTheme() -> SystemTheme
    func setSystemTheme(_ theme: SystemTheme)

    func isFirstLaunch() -> Bool
    func setFirstLaunch(_ value: Bool)

    func recentSearchQueries() -> [String]
    func setRecentSearchQueries(_ queries: [String])

    func pushNotificationSortOrder() -> PushNotificationQuery.SortOrder
    func setPushNotificationSortOrder(_ order: PushNotificationQuery.SortOrder)

    func pushNotificationTimeFilter() -> PushNotificationQuery.TimeFilter
    func setPushNotificationTimeFilter(_ filter: PushNotificationQuery.TimeFilter)

    func pushNotificationUnreadOnly() -> Bool
    func setPushNotificationUnreadOnly(_ value: Bool)
}
