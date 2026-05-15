//
//  WidgetSyncEventHandler.swift
//  DevLog
//
//  Created by opfic on 4/30/26.
//

import Combine
import Foundation
import DevLogDomain
import DevLogData

public final class WidgetSyncEventHandler {
    private let repository: TodoRepository
    private let snapshotUpdater: WidgetSnapshotUpdater
    private let pageSize = 100
    private let logger = Logger(category: "WidgetSyncEventHandler")
    private var cancellables = Set<AnyCancellable>()

    public init(
        eventBus: WidgetSyncEventBus,
        repository: TodoRepository,
        snapshotUpdater: WidgetSnapshotUpdater
    ) {
        self.repository = repository
        self.snapshotUpdater = snapshotUpdater

        eventBus.observe()
            .sink { [weak self] event in
                self?.handle(event)
            }
            .store(in: &cancellables)
    }
}

private extension WidgetSyncEventHandler {
    func handle(_ event: WidgetSyncEvent) {
        switch event {
        case .syncRequested:
            Task { [weak self] in
                guard let self else { return }
                async let todaySnapshot: Void = updateTodayWidgetSnapshot()
                async let heatmapSnapshot: Void = updateHeatmapWidgetSnapshot()
                _ = await (todaySnapshot, heatmapSnapshot)
            }
        }
    }

    func updateTodayWidgetSnapshot() async {
        do {
            async let todosWithDueDate = fetchTodayTodos(
                dueDateFilter: .withDueDate,
                sortTarget: .dueDate,
                sortOrder: .oldest
            )
            async let todosWithoutDueDate = fetchTodayTodos(
                dueDateFilter: .withoutDueDate,
                sortTarget: .updatedAt,
                sortOrder: .latest
            )
            let (todayTodosWithDueDate, todayTodosWithoutDueDate) = try await (
                todosWithDueDate,
                todosWithoutDueDate
            )
            snapshotUpdater.updateTodaySnapshot(
                todos: todayTodosWithDueDate + todayTodosWithoutDueDate,
                now: Date()
            )
        } catch {
            logger.error(
                "Failed to fetch today widget snapshot data.",
                error: error
            )
        }
    }

    func updateHeatmapWidgetSnapshot() async {
        let currentDate = Date()
        let quarterStart = Calendar.current.startOfQuarter(for: currentDate)
        guard let nextQuarterStart = Calendar.current.date(byAdding: .month, value: 3, to: quarterStart) else {
            return
        }

        do {
            async let createdTodos = fetchHeatmapTodos(
                sortTarget: .createdAt,
                quarterStart: quarterStart,
                nextQuarterStart: nextQuarterStart
            )
            async let completedTodos = fetchHeatmapTodos(
                sortTarget: .completedAt,
                quarterStart: quarterStart,
                nextQuarterStart: nextQuarterStart
            )
            async let deletedTodos = fetchHeatmapTodos(
                sortTarget: .deletedAt,
                quarterStart: quarterStart,
                nextQuarterStart: nextQuarterStart
            )
            let (createdTodoItems, completedTodoItems, deletedTodoItems) = try await (
                createdTodos,
                completedTodos,
                deletedTodos
            )
            snapshotUpdater.updateHeatmapSnapshot(
                createdTodos: createdTodoItems,
                completedTodos: completedTodoItems,
                deletedTodos: deletedTodoItems,
                quarterStart: quarterStart,
                now: currentDate
            )
        } catch {
            logger.error(
                "Failed to fetch heatmap widget snapshot data.",
                error: error
            )
        }
    }

    func fetchTodayTodos(
        dueDateFilter: TodoQuery.DueDateFilter,
        sortTarget: TodoQuery.SortTarget,
        sortOrder: TodoQuery.SortOrder
    ) async throws -> [Todo] {
        let todoPage = try await repository.fetchTodos(
            TodoQuery(
                completionFilter: .incomplete,
                dueDateFilter: dueDateFilter,
                sortTarget: sortTarget,
                sortOrder: sortOrder,
                pageSize: pageSize,
                fetchAllPages: true
            ),
            cursor: nil
        )

        return todoPage.items
    }

    func fetchHeatmapTodos(
        sortTarget: TodoQuery.SortTarget,
        quarterStart: Date,
        nextQuarterStart: Date
    ) async throws -> [Todo] {
        let todoPage = try await repository.fetchTodos(
            TodoQuery(
                sortDateFrom: quarterStart,
                sortDateTo: nextQuarterStart,
                includesDeleted: true,
                sortTarget: sortTarget,
                pageSize: pageSize,
                fetchAllPages: true
            ),
            cursor: nil
        )

        return todoPage.items
    }
}
