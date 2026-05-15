//
//  WidgetSnapshotPreferenceStoreTests.swift
//  DevLogStorageTests
//
//  Created by opfic on 4/30/26.
//

import Foundation
import DevLogDomain
import Testing
@testable import DevLogStorage

struct WidgetSnapshotPreferenceStoreTests {
    @Test("Heatmap activity kind 설정이 비어 있으면 전체 kind를 사용한다")
    func heatmap_activity_kind_설정이_비어_있으면_전체_kind를_사용한다() {
        let fixture = makeFixture()

        #expect(fixture.widgetSnapshotPreferenceStore.selectedActivityKinds() == Set([.created, .completed, .deleted]))
    }

    @Test("Heatmap activity kind 설정에 유효하지 않은 값만 있으면 전체 kind를 사용한다")
    func heatmap_activity_kind_설정에_유효하지_않은_값만_있으면_전체_kind를_사용한다() {
        let fixture = makeFixture()

        fixture.widgetSnapshotPreferenceStore.setHeatmapActivityTypes(["unknown"])

        #expect(fixture.widgetSnapshotPreferenceStore.selectedActivityKinds() == Set([.created, .completed, .deleted]))
    }

    @Test("Heatmap activity kind 설정은 유효한 값만 유지한다")
    func heatmap_activity_kind_설정은_유효한_값만_유지한다() {
        let fixture = makeFixture()

        fixture.widgetSnapshotPreferenceStore.setHeatmapActivityTypes(["created", "unknown", "deleted", "created"])

        #expect(fixture.widgetSnapshotPreferenceStore.selectedActivityKinds() == Set([.created, .deleted]))
    }

    @Test("Today display option 설정이 깨져 있으면 기본 옵션을 사용한다")
    func today_display_option_설정이_깨져_있으면_기본_옵션을_사용한다() {
        let fixture = makeFixture()

        fixture.userDefaults.set("invalid", forKey: "Today.dueDateVisibility")
        fixture.userDefaults.set("invalid", forKey: "Today.focusVisibility")

        #expect(fixture.widgetSnapshotPreferenceStore.todayDisplayOptions() == .default)
    }

    private func makeFixture() -> (
        widgetSnapshotPreferenceStore: WidgetSnapshotPreferenceStoreImpl,
        userDefaults: UserDefaults
    ) {
        let suiteName = "WidgetSnapshotPreferenceStoreTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        userDefaults.removePersistentDomain(forName: suiteName)
        let widgetSnapshotPreferenceStore = WidgetSnapshotPreferenceStoreImpl(userDefaults: userDefaults)
        return (widgetSnapshotPreferenceStore, userDefaults)
    }
}
