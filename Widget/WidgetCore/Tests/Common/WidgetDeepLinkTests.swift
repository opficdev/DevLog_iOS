//
//  WidgetDeepLinkTests.swift
//  WidgetCoreTests
//
//  Created by opfic on 9/24/26.
//

import Foundation
import Testing
@testable import WidgetCore

struct WidgetDeepLinkTests {
    @Test("위젯 Todo URL은 ID를 보존해 상세 목적지로 해석한다")
    func 위젯_Todo_URL은_ID를_보존해_상세_목적지로_해석한다() throws {
        let id = "todo/1?한글"
        let url = try #require(WidgetDeepLink.todoURL(id: id))

        #expect(WidgetDeepLink.destination(for: url) == .todo(id))
    }

    @Test("기존 위젯 URL은 탭 목적지로 해석한다")
    func 기존_위젯_URL은_탭_목적지로_해석한다() throws {
        let todayURL = try #require(WidgetDeepLink.todayTodoURL)
        let heatmapURL = try #require(WidgetDeepLink.heatmapURL)

        #expect(WidgetDeepLink.destination(for: todayURL) == .today)
        #expect(WidgetDeepLink.destination(for: heatmapURL) == .profile)
    }

    @Test("Todo ID가 비어 있거나 URL 형식이 다르면 목적지를 만들지 않는다")
    func Todo_ID가_비어_있거나_URL_형식이_다르면_목적지를_만들지_않는다() throws {
        #expect(WidgetDeepLink.todoURL(id: "") == nil)
        let url = try #require(URL(string: "DevLog://today?todoId="))
        let wrongSchemeURL = try #require(URL(string: "https://today?todoId=todo-1"))

        #expect(WidgetDeepLink.destination(for: url) == nil)
        #expect(WidgetDeepLink.destination(for: wrongSchemeURL) == nil)
    }
}
