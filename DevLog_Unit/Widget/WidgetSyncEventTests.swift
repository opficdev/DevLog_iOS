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
    @Test("위젯 동기화 이벤트는 동기화 요청만 표현한다")
    func 위젯_동기화_이벤트는_동기화_요청만_표현한다() {
        #expect(WidgetSyncEvent.syncRequested == .syncRequested)
    }
}
