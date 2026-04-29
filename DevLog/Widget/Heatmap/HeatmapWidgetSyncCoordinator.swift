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
    private let logger = Logger(category: "HeatmapWidgetSyncCoordinator")

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
        let quarterStart = startOfQuarter(for: now)
        guard let nextQuarterStart = calendar.date(byAdding: .month, value: 3, to: quarterStart) else {
            return
        }

        do {
            async let createdTodoPage = fetchTodosUseCase.execute(
                TodoQuery(
                    sortDateFrom: quarterStart,
                    sortDateTo: nextQuarterStart,
                    includesDeleted: true,
                    sortTarget: .createdAt,
                    pageSize: 100,
                    fetchAllPages: true
                ),
                cursor: nil
            )
            async let completedTodoPage = fetchTodosUseCase.execute(
                TodoQuery(
                    sortDateFrom: quarterStart,
                    sortDateTo: nextQuarterStart,
                    includesDeleted: true,
                    sortTarget: .completedAt,
                    pageSize: 100,
                    fetchAllPages: true
                ),
                cursor: nil
            )
            async let deletedTodoPage = fetchTodosUseCase.execute(
                TodoQuery(
                    sortDateFrom: quarterStart,
                    sortDateTo: nextQuarterStart,
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
                quarterStart: quarterStart,
                now: now
            )

            try store.saveHeatmapSnapshot(snapshot)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.heatmap)
        } catch is CancellationError {
            logger.debug("Heatmap widget sync cancelled.")
        } catch {
            logger.error(
                "Failed to sync heatmap widget snapshot.",
                error: error
            )
        }
    }
}

private extension HeatmapWidgetSyncCoordinator {
    func startOfQuarter(for date: Date) -> Date {
        let month = calendar.component(.month, from: date)
        let startMonth = ((month - 1) / 3) * 3 + 1
        var components = calendar.dateComponents([.year], from: date)
        components.month = startMonth
        components.day = 1
        return calendar.date(from: components) ?? calendar.startOfDay(for: date)
    }
}
