//
//  UserPreferencesRepositoryImplTests.swift
//  DevLogDataTests
//
//  Created by opfic on 6/1/26.
//

import Combine
import Foundation
import Testing
import DevLogCore
@testable import DevLogData

struct UserPreferencesRepositoryImplTests {
    @Test("위젯 설정 변경 시 위젯 동기화 이벤트를 발행한다")
    func 위젯_설정_변경_시_위젯_동기화_이벤트를_발행한다() {
        let widgetSnapshotPreferenceStore = WidgetSnapshotPreferenceStoreSpy()
        let widgetSyncEventBus = WidgetSyncEventBusSpy()
        let repository = UserPreferencesRepositoryImpl(
            store: UserDefaultsStoreSpy(),
            themeStore: ThemeStoreSpy(),
            widgetSnapshotPreferenceStore: widgetSnapshotPreferenceStore,
            widgetSyncEventBus: widgetSyncEventBus
        )

        repository.setHeatmapActivityTypes(["created", "deleted"])
        repository.setTodayDisplayOptions(
            TodayDisplayOptions(
                dueDateVisibility: .withDueDateOnly,
                focusVisibility: .focusedOnly
            )
        )

        #expect(widgetSnapshotPreferenceStore.heatmapActivityTypesValue == ["created", "deleted"])
        #expect(
            widgetSnapshotPreferenceStore.todayDisplayOptionsValue == TodayDisplayOptions(
                dueDateVisibility: .withDueDateOnly,
                focusVisibility: .focusedOnly
            )
        )
        #expect(widgetSyncEventBus.events == [.syncRequested, .syncRequested])
    }
}

private final class UserDefaultsStoreSpy: UserDefaultsStore {
    func value<T: Codable>(forKey key: String) -> T? {
        nil
    }

    func setValue<T: Codable>(_ value: T?, forKey key: String) { }

    func removeValues(withPrefix prefix: String) { }

    func string(forKey key: String) -> String? {
        nil
    }

    func setString(_ value: String?, forKey key: String) { }

    func stringArray(forKey key: String) -> [String] {
        []
    }

    func setStringArray(_ value: [String], forKey key: String) { }

    func bool(forKey key: String) -> Bool {
        false
    }

    func setBool(_ value: Bool, forKey key: String) { }
}

private final class ThemeStoreSpy: ThemeStore {
    func observeTheme() -> AnyPublisher<SystemTheme, Never> {
        Empty().eraseToAnyPublisher()
    }

    func send(_ theme: SystemTheme) { }
}

private final class WidgetSnapshotPreferenceStoreSpy: WidgetSnapshotPreferenceStore {
    private(set) var heatmapActivityTypesValue = [String]()
    private(set) var todayDisplayOptionsValue = TodayDisplayOptions.default

    func heatmapActivityTypes() -> [String] {
        heatmapActivityTypesValue
    }

    func setHeatmapActivityTypes(_ activityTypes: [String]) {
        heatmapActivityTypesValue = activityTypes
    }

    func selectedActivityKinds() -> Set<ActivityKind> {
        []
    }

    func todayDisplayOptions() -> TodayDisplayOptions {
        todayDisplayOptionsValue
    }

    func setTodayDisplayOptions(_ options: TodayDisplayOptions) {
        todayDisplayOptionsValue = options
    }

    func clear() { }
}

private final class WidgetSyncEventBusSpy: WidgetSyncEventBus {
    private(set) var events = [WidgetSyncEvent]()

    func publish(_ event: WidgetSyncEvent) {
        events.append(event)
    }

    func request() { }

    func confirmRequest() -> Bool {
        false
    }

    func observe() -> AnyPublisher<WidgetSyncEvent, Never> {
        Empty().eraseToAnyPublisher()
    }
}
