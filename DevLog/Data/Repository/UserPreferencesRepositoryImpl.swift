//
//  UserPreferencesRepositoryImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/25/26.
//

import Foundation
import Combine

final class UserPreferencesRepositoryImpl: UserPreferencesRepository {
    private enum Key {
        static let theme = "theme"
        static let firstLaunch = "isFirstLaunch"
        static let recentQueries = "Search.recentQueries"
        static let pushSortOrder = "PushNotification.sortOption"
        static let pushTimeFilter = "PushNotification.timeFilter"
        static let pushUnreadOnly = "PushNotification.showUnreadOnly"
        static let profileHeatmapActivityTypes = "Profile.heatmap.activityTypes"
        static let todayDueDateVisibility = "Today.dueDateVisibility"
        static let todayFocusVisibility = "Today.focusVisibility"
    }

    private let store: UserDefaultsStore
    private let themeStore: ThemeStore

    init(
        store: UserDefaultsStore,
        themeStore: ThemeStore
    ) {
        self.store = store
        self.themeStore = themeStore
        themeStore.send(systemTheme())
    }

    var systemThemePublisher: AnyPublisher<SystemTheme, Never> {
        themeStore.themePublisher
    }

    func systemTheme() -> SystemTheme {
        guard let rawValue = store.string(forKey: Key.theme),
              let theme = SystemTheme(rawValue: rawValue) else {
            return .automatic
        }
        return theme
    }

    func setSystemTheme(_ theme: SystemTheme) {
        store.setString(theme.rawValue, forKey: Key.theme)
        themeStore.send(theme)
    }

    func isFirstLaunch() -> Bool {
        if store.string(forKey: Key.firstLaunch) == nil {
            return true
        }
        return store.bool(forKey: Key.firstLaunch)
    }

    func setFirstLaunch(_ value: Bool) {
        store.setBool(value, forKey: Key.firstLaunch)
    }

    func recentSearchQueries() -> [String] {
        store.stringArray(forKey: Key.recentQueries)
    }

    func setRecentSearchQueries(_ queries: [String]) {
        store.setStringArray(queries, forKey: Key.recentQueries)
    }

    func pushNotificationSortOrder() -> PushNotificationQuery.SortOrder {
        guard let rawValue = store.string(forKey: Key.pushSortOrder) else { return .latest }
        return rawValue == "oldest" ? .oldest : .latest
    }

    func setPushNotificationSortOrder(_ order: PushNotificationQuery.SortOrder) {
        let value = order == .oldest ? "oldest" : "latest"
        store.setString(value, forKey: Key.pushSortOrder)
    }

    func pushNotificationTimeFilter() -> PushNotificationQuery.TimeFilter {
        let id = store.string(forKey: Key.pushTimeFilter) ?? "none"
        return PushNotificationQuery.TimeFilter(id: id)
    }

    func setPushNotificationTimeFilter(_ filter: PushNotificationQuery.TimeFilter) {
        store.setString(filter.id, forKey: Key.pushTimeFilter)
    }

    func pushNotificationUnreadOnly() -> Bool {
        store.bool(forKey: Key.pushUnreadOnly)
    }

    func setPushNotificationUnreadOnly(_ value: Bool) {
        store.setBool(value, forKey: Key.pushUnreadOnly)
    }

    func profileHeatmapActivityTypes() -> [String] {
        store.stringArray(forKey: Key.profileHeatmapActivityTypes)
    }

    func setProfileHeatmapActivityTypes(_ activityTypes: [String]) {
        store.setStringArray(activityTypes, forKey: Key.profileHeatmapActivityTypes)
    }

    func todayDisplayOptions() -> TodayDisplayOptions {
        let dueDateVisibilityRawValue = store.string(forKey: Key.todayDueDateVisibility)
        let focusVisibilityRawValue = store.string(forKey: Key.todayFocusVisibility)

        return TodayDisplayOptions(
            dueDateVisibility: TodayDisplayOptions.DueDateVisibility(
                rawValue: dueDateVisibilityRawValue ?? ""
            ) ?? .all,
            focusVisibility: TodayDisplayOptions.FocusVisibility(
                rawValue: focusVisibilityRawValue ?? ""
            ) ?? .all
        )
    }

    func setTodayDisplayOptions(_ options: TodayDisplayOptions) {
        store.setString(options.dueDateVisibility.rawValue, forKey: Key.todayDueDateVisibility)
        store.setString(options.focusVisibility.rawValue, forKey: Key.todayFocusVisibility)
    }
}
