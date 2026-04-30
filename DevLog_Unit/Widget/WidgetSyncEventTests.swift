//
//  WidgetSyncEventTests.swift
//  DevLog_Unit
//
//  Created by opfic on 4/29/26.
//

import Foundation
import Testing
@testable import DevLog

struct WidgetSyncEventTests {
    @Test("위젯 동기화 이벤트는 변경 원인만 표현한다")
    func 위젯_동기화_이벤트는_변경_원인만_표현한다() {
        #expect(WidgetSyncEvent.todoDataChanged == .todoDataChanged)
        #expect(WidgetSyncEvent.todayDisplayOptionsChanged == .todayDisplayOptionsChanged)
        #expect(WidgetSyncEvent.heatmapActivityKindsChanged == .heatmapActivityKindsChanged)
    }
}
