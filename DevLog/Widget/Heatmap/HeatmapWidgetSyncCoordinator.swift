//
//  HeatmapWidgetSyncCoordinator.swift
//  DevLog
//
//  Created by opfic on 4/17/26.
//

import Foundation
import WidgetKit

final class HeatmapWidgetSyncCoordinator {
    private let fetchTodosUseCase: FetchTodosUseCase
    private let factory: HeatmapWidgetSnapshotFactory
    private let store: WidgetSnapshotStore
    private let calendar: Calendar

    init(
        fetchTodosUseCase: FetchTodosUseCase,
        factory: HeatmapWidgetSnapshotFactory = .init(),
        store: WidgetSnapshotStore = .init(),
        calendar: Calendar = .current
    ) {
        self.fetchTodosUseCase = fetchTodosUseCase
        self.factory = factory
        self.store = store
        self.calendar = calendar
    }

    func sync(
        selectedActivityKinds: Set<ActivityKind>,
        now: Date = Date()
    ) async {
        let monthStart = startOfMonth(for: now)
        guard let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return
        }

        do {
            async let createdTodoPage = fetchTodosUseCase.execute(
                TodoQuery(
                    sortDateFrom: monthStart,
                    sortDateTo: nextMonthStart,
                    includesDeleted: true,
                    sortTarget: .createdAt,
                    pageSize: 100,
                    fetchAllPages: true
                ),
                cursor: nil
            )
            async let completedTodoPage = fetchTodosUseCase.execute(
                TodoQuery(
                    sortDateFrom: monthStart,
                    sortDateTo: nextMonthStart,
                    includesDeleted: true,
                    sortTarget: .completedAt,
                    pageSize: 100,
                    fetchAllPages: true
                ),
                cursor: nil
            )
            async let deletedTodoPage = fetchTodosUseCase.execute(
                TodoQuery(
                    sortDateFrom: monthStart,
                    sortDateTo: nextMonthStart,
                    includesDeleted: true,
                    sortTarget: .deletedAt,
                    pageSize: 100,
                    fetchAllPages: true
                ),
                cursor: nil
            )

            let snapshot = factory.makeSnapshot(
                createdTodos: try await createdTodoPage.items,
                completedTodos: try await completedTodoPage.items,
                deletedTodos: try await deletedTodoPage.items,
                selectedActivityKinds: selectedActivityKinds,
                monthStart: monthStart,
                now: now
            )

            try store.saveHeatmapSnapshot(snapshot)
            WidgetCenter.shared.reloadTimelines(ofKind: "HeatmapWidget")
        } catch {
            return
        }
    }
}

private extension HeatmapWidgetSyncCoordinator {
    func startOfMonth(for date: Date) -> Date {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return calendar.startOfDay(for: date)
        }

        return monthInterval.start
    }
}
