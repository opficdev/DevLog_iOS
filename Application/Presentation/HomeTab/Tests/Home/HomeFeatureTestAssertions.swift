//
//  HomeFeatureTestAssertions.swift
//  PresentationTests
//
//  Created by opfic on 6/14/26.
//

import Testing
import Foundation
import Domain
@testable import Presentation

@MainActor
func verifyHomeFetchData(
    adapter: HomeStoreTestAdapter,
    fetchTodosUseCaseSpy: FetchTodosUseCaseSpy,
    fetchWebPagesUseCaseSpy: FetchWebPagesUseCaseSpy
) async throws {
    await adapter.fetchData()

    await waitUntil {
        adapter.preferences.count == 2
            && adapter.recentTodos.count == 2
            && adapter.webPages.count == 1
    }

    #expect(adapter.preferences.map(\.id) == ["feature", "custom"])
    #expect(adapter.recentTodos.map(\.id) == ["todo-1", "todo-2"])
    #expect(adapter.webPages.map(\.url.absoluteString) == ["https://openai.com"])
    #expect(fetchTodosUseCaseSpy.queries.count == 1)
    #expect(fetchTodosUseCaseSpy.queries.first?.sortTarget == .updatedAt)
    #expect(fetchTodosUseCaseSpy.queries.first?.sortOrder == .latest)
    #expect(fetchTodosUseCaseSpy.queries.first?.pageSize == 100)
    #expect(fetchWebPagesUseCaseSpy.calledQueries == [""])
}

@MainActor
func verifyHomeWebPageInputAlert(
    adapter: HomeStoreTestAdapter
) async throws {
    await adapter.setPresentation(.contentPicker, true)

    #expect(adapter.showContentPicker)

    await adapter.openWebPageInput()

    #expect(adapter.showContentPicker)
    #expect(!adapter.showAlert)

    await waitUntil {
        adapter.showWebPageInputNavigation
    }

    #expect(adapter.showWebPageInputNavigation)
    #expect(adapter.webPageURLInput == "https://")
}

@MainActor
func verifyHomeTapTodoCategory(
    adapter: HomeStoreTestAdapter
) async throws {
    await adapter.setPresentation(.contentPicker, true)
    await adapter.tapTodoCategory(.system(.feature))

    #expect(!adapter.showContentPicker)
    #expect(adapter.showTodoEditor)
}

@MainActor
func verifyHomeOrderTodoCategory(
    adapter: HomeStoreTestAdapter,
    updatePreferencesUseCaseSpy: UpdateTodoCategoryPreferencesUseCaseSpy
) async throws {
    await adapter.fetchData()

    let updatedCategory = TodoCategoryItem(
        from: .user(
            UserTodoCategory(
                id: "custom",
                name: "Updated",
                colorHex: "#222222"
            )
        )
    )
    let items = [
        updatedCategory,
        TodoCategoryItem(from: .system(.feature))
    ]

    await adapter.tapManageTodoCategory()

    #expect(adapter.showCategoryManage)

    await adapter.orderTodoCategory(items)

    #expect(adapter.preferences == items)
    #expect(adapter.recentTodos.last?.category == updatedCategory.category)
    #expect(updatePreferencesUseCaseSpy.updates == [items.map(\.preference)])
    #expect(!adapter.showCategoryManage)
}

@MainActor
func verifyHomeAddWebPage(
    adapter: HomeStoreTestAdapter,
    addWebPageUseCaseSpy: AddWebPageUseCaseSpy,
    fetchWebPagesUseCaseSpy: FetchWebPagesUseCaseSpy,
    trackAnalyticsEventUseCaseSpy: HomeTrackAnalyticsEventUseCaseSpy
) async throws {
    await adapter.setPresentation(.contentPicker, true)
    await adapter.updateWebPageURLInput("openai.com")
    await adapter.addWebPage()

    await waitUntil {
        addWebPageUseCaseSpy.calledUrlStrings == ["https://openai.com"]
            && adapter.webPages.count == 2
    }

    #expect(addWebPageUseCaseSpy.calledUrlStrings == ["https://openai.com"])
    #expect(fetchWebPagesUseCaseSpy.calledQueries == [""])
    #expect(trackAnalyticsEventUseCaseSpy.events.count == 1)
    #expect(adapter.webPages.map(\.url.absoluteString) == [
        "https://openai.com",
        "https://developer.apple.com"
    ])
    #expect(!adapter.showContentPicker)
    #expect(!adapter.showAlert)
}

@MainActor
func verifyHomeAddWebPageFailureKeepsSheet(
    adapter: HomeStoreTestAdapter,
    addWebPageUseCaseSpy: AddWebPageUseCaseSpy
) async throws {
    await adapter.setPresentation(.contentPicker, true)
    await adapter.updateWebPageURLInput("openai.com")
    await adapter.addWebPage()

    await waitUntil {
        addWebPageUseCaseSpy.calledUrlStrings == ["https://openai.com"]
            && adapter.showAlert
    }

    #expect(adapter.showContentPicker)
    #expect(adapter.alertType == .error)
}

struct HomeFetchDataContext {
    let fetchPreferencesUseCaseSpy: FetchTodoCategoryPreferencesUseCaseSpy
    let fetchTodosUseCaseSpy: FetchTodosUseCaseSpy
    let fetchWebPagesUseCaseSpy: FetchWebPagesUseCaseSpy
}

func makeHomeFetchDataContext() -> HomeFetchDataContext {
    let fetchPreferencesUseCaseSpy = FetchTodoCategoryPreferencesUseCaseSpy()
    fetchPreferencesUseCaseSpy.todoCategoryPreferences = [
        TodoCategoryPreference(category: .system(.feature), isVisible: true),
        TodoCategoryPreference(
            category: .user(
                UserTodoCategory(
                    id: "custom",
                    name: "Custom",
                    colorHex: "#111111"
                )
            ),
            isVisible: true
        )
    ]

    let fetchTodosUseCaseSpy = FetchTodosUseCaseSpy()
    let createdAt = Date(timeIntervalSince1970: 0)
    fetchTodosUseCaseSpy.todoPage = TodoPage(
        items: [
            makeHomeTodo(id: "todo-1", category: .system(.feature), number: 1),
            makeHomeTodo(
                id: "todo-2",
                category: .user(
                    UserTodoCategory(
                        id: "custom",
                        name: "Custom",
                        colorHex: "#111111"
                    )
                ),
                number: 2
            ),
            makeHomeTodo(
                id: "todo-ignored",
                number: 3,
                createdAt: createdAt,
                updatedAt: createdAt
            )
        ],
        nextCursor: nil
    )

    let fetchWebPagesUseCaseSpy = FetchWebPagesUseCaseSpy(
        webPages: [makeHomeWebPage()]
    )

    return HomeFetchDataContext(
        fetchPreferencesUseCaseSpy: fetchPreferencesUseCaseSpy,
        fetchTodosUseCaseSpy: fetchTodosUseCaseSpy,
        fetchWebPagesUseCaseSpy: fetchWebPagesUseCaseSpy
    )
}

struct HomeOrderContext {
    let fetchPreferencesUseCaseSpy: FetchTodoCategoryPreferencesUseCaseSpy
    let updatePreferencesUseCaseSpy: UpdateTodoCategoryPreferencesUseCaseSpy
    let fetchTodosUseCaseSpy: FetchTodosUseCaseSpy
}

func makeHomeOrderContext() -> HomeOrderContext {
    let fetchContext = makeHomeFetchDataContext()
    return HomeOrderContext(
        fetchPreferencesUseCaseSpy: fetchContext.fetchPreferencesUseCaseSpy,
        updatePreferencesUseCaseSpy: UpdateTodoCategoryPreferencesUseCaseSpy(),
        fetchTodosUseCaseSpy: fetchContext.fetchTodosUseCaseSpy
    )
}

struct HomeAddWebPageContext {
    let addWebPageUseCaseSpy: AddWebPageUseCaseSpy
    let fetchWebPagesUseCaseSpy: FetchWebPagesUseCaseSpy
    let trackAnalyticsEventUseCaseSpy: HomeTrackAnalyticsEventUseCaseSpy
}

func makeHomeAddWebPageContext() -> HomeAddWebPageContext {
    HomeAddWebPageContext(
        addWebPageUseCaseSpy: AddWebPageUseCaseSpy(),
        fetchWebPagesUseCaseSpy: FetchWebPagesUseCaseSpy(
            webPages: [
                makeHomeWebPage(),
                makeHomeWebPage(
                    title: "Apple",
                    urlString: "https://developer.apple.com"
                )
            ]
        ),
        trackAnalyticsEventUseCaseSpy: HomeTrackAnalyticsEventUseCaseSpy()
    )
}

struct HomeDeleteContext {
    let addWebPageUseCaseSpy: AddWebPageUseCaseSpy
    let fetchWebPagesUseCaseSpy: FetchWebPagesUseCaseSpy
    let deleteWebPageUseCaseSpy: DeleteWebPageUseCaseSpy
    let undoDeleteWebPageUseCaseSpy: UndoDeleteWebPageUseCaseSpy
}

func makeHomeDeleteContext() -> HomeDeleteContext {
    HomeDeleteContext(
        addWebPageUseCaseSpy: AddWebPageUseCaseSpy(),
        fetchWebPagesUseCaseSpy: FetchWebPagesUseCaseSpy(webPages: [makeHomeWebPage()]),
        deleteWebPageUseCaseSpy: DeleteWebPageUseCaseSpy(),
        undoDeleteWebPageUseCaseSpy: UndoDeleteWebPageUseCaseSpy()
    )
}
