//
//  WidgetSharedConstantsTests.swift
//  WidgetCoreTests
//
//  Created by opfic on 4/29/26.
//

import Testing
@testable import WidgetCore

struct WidgetSharedConstantsTests {
    @Test("위젯 kind와 snapshot key는 공유 상수로 관리한다")
    func 위젯_kind와_snapshot_key는_공유_상수로_관리한다() {
        #expect(WidgetKind.todayTodo == "TodayTodoWidget")
        #expect(WidgetKind.heatmap == "HeatmapWidget")
        #expect(WidgetSnapshotKey.today == "Widget.today.snapshot")
        #expect(WidgetSnapshotKey.heatmap == "Widget.heatmap.snapshot")
    }
}
