//
//  HomeFeatureTestAssertions.swift
//  HomeTabTests
//
//  Created by opfic on 6/14/26.
//

import Testing
import Foundation
import Domain
import PresentationShared
@testable import HomeTab

@MainActor
func verifyHomeFetchData(
    adapter: HomeStoreTestAdapter
) async throws {
    await adapter.fetchData()

    await waitUntil {
        adapter.preferences.count == 2
    }

    #expect(adapter.preferences.map(\.id) == ["feature", "custom"])
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
    #expect(updatePreferencesUseCaseSpy.updates == [items.map(\.preference)])
    #expect(!adapter.showCategoryManage)
}

struct HomeFetchDataContext {
    let fetchPreferencesUseCaseSpy: FetchTodoCategoryPreferencesUseCaseSpy
}

func makeDevelopmentGoal(
    id: String,
    createdAt: TimeInterval
) throws -> DevelopmentGoal {
    try DevelopmentGoal(
        id: id,
        title: "Goal \(id)",
        description: "Description",
        status: .inProgress,
        createdAt: Date(timeIntervalSinceReferenceDate: createdAt),
        updatedAt: Date(timeIntervalSinceReferenceDate: createdAt),
        completedAt: nil
    )
}

func makeDevelopmentRecord(
    id: String,
    goalId: String,
    versionID: String
) throws -> DevelopmentRecord {
    try DevelopmentRecord(
        id: id,
        goalId: goalId,
        currentVersion: .init(id: versionID, number: 1),
        draft: nil,
        createdAt: .now
    )
}

func makeDevelopmentRecordVersion(
    id: String,
    recordID: String,
    title: String,
    confirmedAt: TimeInterval
) throws -> DevelopmentRecord.Version {
    try DevelopmentRecord.Version(
        id: id,
        recordId: recordID,
        number: 1,
        title: title,
        markdownContent: "",
        kind: .initial,
        sourceVersionId: nil,
        confirmedAt: Date(timeIntervalSinceReferenceDate: confirmedAt)
    )
}

func makeHomeTodo(
    id: String,
    goalID: String?,
    isCompleted: Bool
) -> Todo {
    Todo(
        id: id,
        isPinned: false,
        isCompleted: isCompleted,
        isChecked: false,
        number: 1,
        title: "Todo \(id)",
        content: "",
        createdAt: .now,
        updatedAt: .now,
        completedAt: isCompleted ? .now : nil,
        deletedAt: nil,
        dueDate: nil,
        tags: [],
        category: .system(.feature),
        goalId: goalID
    )
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

    return HomeFetchDataContext(
        fetchPreferencesUseCaseSpy: fetchPreferencesUseCaseSpy
    )
}

struct HomeOrderContext {
    let fetchPreferencesUseCaseSpy: FetchTodoCategoryPreferencesUseCaseSpy
    let updatePreferencesUseCaseSpy: UpdateTodoCategoryPreferencesUseCaseSpy
}

func makeHomeOrderContext() -> HomeOrderContext {
    let fetchContext = makeHomeFetchDataContext()
    return HomeOrderContext(
        fetchPreferencesUseCaseSpy: fetchContext.fetchPreferencesUseCaseSpy,
        updatePreferencesUseCaseSpy: UpdateTodoCategoryPreferencesUseCaseSpy()
    )
}
