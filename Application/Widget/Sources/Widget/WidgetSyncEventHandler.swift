//
//  WidgetSyncEventHandler.swift
//  Widget
//
//  Created by opfic on 4/30/26.
//

import Combine
import Foundation
import Core
import Data
import WidgetCore

public final class WidgetSyncEventHandler {
    private let repository: WidgetTodoSnapshotRepository
    private let snapshotUpdater: WidgetSnapshotUpdater
    private let pageSize = 100
    private let logger = Logger(category: "WidgetSyncEventHandler")
    private var cancellables = Set<AnyCancellable>()

    public init(
        eventBus: WidgetSyncEventBus,
        repository: WidgetTodoSnapshotRepository,
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
                let now = Date()
                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await self.updateTodayWidgetSnapshot(now: now) }
                    group.addTask { await self.updateHeatmapWidgetSnapshot(now: now) }
                }
            }
        case .refreshRequested:
            let now = Date()
            snapshotUpdater.updateTodaySnapshot(now: now)
            snapshotUpdater.updateHeatmapSnapshot(now: now)
        }
    }

    func updateTodayWidgetSnapshot(now: Date) async {
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
                now: now
            )
        } catch {
            logger.error(
                "Failed to fetch today widget snapshot data.",
                error: error
            )
        }
    }

    func updateHeatmapWidgetSnapshot(now: Date) async {
        let quarterStart = Calendar.current.startOfQuarter(for: now)
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
                now: now
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
    ) async throws -> [WidgetTodoSnapshot] {
        try await repository.fetchTodayTodos(
            dueDateFilter: dueDateFilter,
            sortTarget: sortTarget,
            sortOrder: sortOrder,
            pageSize: pageSize
        )
    }

    func fetchHeatmapTodos(
        sortTarget: TodoQuery.SortTarget,
        quarterStart: Date,
        nextQuarterStart: Date
    ) async throws -> [WidgetTodoSnapshot] {
        try await repository.fetchHeatmapTodos(
            sortTarget: sortTarget,
            quarterStart: quarterStart,
            nextQuarterStart: nextQuarterStart,
            pageSize: pageSize
        )
    }
}
