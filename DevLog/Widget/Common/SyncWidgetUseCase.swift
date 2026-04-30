//
//  SyncWidgetUseCase.swift
//  DevLog
//
//  Created by opfic on 4/29/26.
//

import Foundation

final class SyncWidgetUseCase {
    private let todoRepository: TodoRepository
    private let widgetRepository: WidgetRepository
    private let todayFactory: TodayWidgetSnapshotFactory
    private let heatmapFactory: HeatmapWidgetSnapshotFactory
    private let calendar: Calendar
    private let logger = Logger(category: "SyncWidgetUseCase")

    init(
        todoRepository: TodoRepository,
        widgetRepository: WidgetRepository,
        todayFactory: TodayWidgetSnapshotFactory = .init(),
        heatmapFactory: HeatmapWidgetSnapshotFactory = .init(),
        calendar: Calendar = .current
    ) {
        self.todoRepository = todoRepository
        self.widgetRepository = widgetRepository
        self.todayFactory = todayFactory
        self.heatmapFactory = heatmapFactory
        self.calendar = calendar
    }

    func execute(
        _ event: WidgetSyncEvent,
        now: Date = Date()
    ) async {
        switch event {
        case .todaySnapshotChanged(let todos, let displayOptions):
            syncTodaySnapshot(
                todos: todos,
                displayOptions: displayOptions,
                now: now
            )
        case .heatmapSnapshotChanged(let selectedActivityKinds):
            await syncHeatmapSnapshot(
                selectedActivityKinds: selectedActivityKinds,
                now: now
            )
        }
    }
}

private extension SyncWidgetUseCase {
    func syncTodaySnapshot(
        todos: [TodayTodoItem],
        displayOptions: TodayDisplayOptions,
        now: Date
    ) {
        let todayWidgetSnapshot = todayFactory.makeSnapshot(
            todos: todos,
            displayOptions: displayOptions,
            now: now
        )

        do {
            try widgetRepository.saveTodaySnapshot(todayWidgetSnapshot)
            widgetRepository.reloadTodayWidget()
        } catch {
            logger.error(
                "Failed to sync today widget snapshot.",
                error: error
            )
        }
    }

    func syncHeatmapSnapshot(
        selectedActivityKinds: Set<ActivityKind>,
        now: Date
    ) async {
        let quarterStart = startOfQuarter(for: now)
        guard let nextQuarterStart = calendar.date(byAdding: .month, value: 3, to: quarterStart) else {
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

            let heatmapWidgetSnapshot = try await heatmapFactory.makeSnapshot(
                createdTodos: createdTodos,
                completedTodos: completedTodos,
                deletedTodos: deletedTodos,
                selectedActivityKinds: selectedActivityKinds,
                quarterStart: quarterStart,
                now: now
            )

            try widgetRepository.saveHeatmapSnapshot(heatmapWidgetSnapshot)
            widgetRepository.reloadHeatmapWidget()
        } catch is CancellationError {
            logger.debug("Heatmap widget sync cancelled.")
        } catch {
            logger.error(
                "Failed to sync heatmap widget snapshot.",
                error: error
            )
        }
    }

    func fetchHeatmapTodos(
        sortTarget: TodoQuery.SortTarget,
        quarterStart: Date,
        nextQuarterStart: Date
    ) async throws -> [Todo] {
        let todoPage = try await todoRepository.fetchTodos(
            TodoQuery(
                sortDateFrom: quarterStart,
                sortDateTo: nextQuarterStart,
                includesDeleted: true,
                sortTarget: sortTarget,
                pageSize: 100,
                fetchAllPages: true
            ),
            cursor: nil
        )

        return todoPage.items
    }

    func startOfQuarter(for date: Date) -> Date {
        let month = calendar.component(.month, from: date)
        let startMonth = ((month - 1) / 3) * 3 + 1
        var components = calendar.dateComponents([.year], from: date)
        components.month = startMonth
        components.day = 1
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }
}
