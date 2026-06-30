//
//  WidgetSnapshotUpdaterImpl.swift
//  DevLogWidget
//
//  Created by opfic on 4/30/26.
//

import Foundation
import WidgetKit
import DevLogCore
import DevLogData
import DevLogWidgetCore

final class WidgetSnapshotUpdaterImpl: WidgetSnapshotUpdater {
    private struct SnapshotSource {
        var hasTodaySource = false
        var hasHeatmapSource = false
        var todayTodos = [WidgetTodoSnapshot]()
        var createdTodos = [WidgetTodoSnapshot]()
        var completedTodos = [WidgetTodoSnapshot]()
        var deletedTodos = [WidgetTodoSnapshot]()
        var quarterStart: Date?
    }

    private let snapshotStore: WidgetSnapshotStore
    private let preferenceStore: WidgetSnapshotPreferenceStore
    private let todayFactory: TodayWidgetSnapshotFactory
    private let heatmapFactory: HeatmapWidgetSnapshotFactory
    private let logger = Logger(category: "WidgetSnapshotUpdaterImpl")
    private let lock = NSLock()
    private var source = SnapshotSource()

    init(
        snapshotStore: WidgetSnapshotStore,
        preferenceStore: WidgetSnapshotPreferenceStore,
        todayFactory: TodayWidgetSnapshotFactory = .init(),
        heatmapFactory: HeatmapWidgetSnapshotFactory = .init()
    ) {
        self.snapshotStore = snapshotStore
        self.preferenceStore = preferenceStore
        self.todayFactory = todayFactory
        self.heatmapFactory = heatmapFactory
    }

    func updateTodaySnapshot(
        todos: [WidgetTodoSnapshot]?,
        displayOptions: TodayDisplayOptions?,
        now: Date = Date()
    ) {
        guard let todos = updateTodaySource(todos) else { return }
        let todayWidgetSnapshot = todayFactory.makeSnapshot(
            todos: todos,
            displayOptions: displayOptions ?? preferenceStore.todayDisplayOptions(),
            now: now
        )

        do {
            try snapshotStore.saveTodaySnapshot(todayWidgetSnapshot)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.todayTodo)
        } catch {
            logger.error(
                "Failed to update today widget snapshot.",
                error: error
            )
        }
    }

    func updateHeatmapSnapshot(
        createdTodos: [WidgetTodoSnapshot]?,
        completedTodos: [WidgetTodoSnapshot]?,
        deletedTodos: [WidgetTodoSnapshot]?,
        quarterStart: Date?,
        now: Date = Date()
    ) {
        guard let source = updateHeatmapSource(
            createdTodos: createdTodos,
            completedTodos: completedTodos,
            deletedTodos: deletedTodos,
            quarterStart: quarterStart
        ),
              let quarterStart = source.quarterStart else { return }
        let heatmapWidgetSnapshot = heatmapFactory.makeSnapshot(
            createdTodos: source.createdTodos,
            completedTodos: source.completedTodos,
            deletedTodos: source.deletedTodos,
            selectedActivityKinds: preferenceStore.selectedActivityKinds(),
            quarterStart: quarterStart,
            now: now
        )

        do {
            try snapshotStore.saveHeatmapSnapshot(heatmapWidgetSnapshot)
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.heatmap)
        } catch {
            logger.error(
                "Failed to update heatmap widget snapshot.",
                error: error
            )
        }
    }

    func upsertTodoSnapshot(
        _ todo: WidgetTodoSnapshot,
        now: Date = Date()
    ) {
        lock.lock()
        upsertTodaySource(todo)
        upsertHeatmapSource(todo)
        lock.unlock()

        updateTodaySnapshot(todos: nil, now: now)
        updateHeatmapSnapshot(
            createdTodos: nil,
            completedTodos: nil,
            deletedTodos: nil,
            quarterStart: nil,
            now: now
        )
    }

    func deleteTodoSnapshot(
        todoId: String,
        deletedAt: Date,
        now: Date = Date()
    ) {
        lock.lock()
        source.todayTodos.removeAll { $0.id == todoId }
        if let todo = sourceTodo(id: todoId) {
            upsertHeatmapSource(todo.withDeletedAt(deletedAt))
        }
        lock.unlock()

        updateTodaySnapshot(todos: nil, now: now)
        updateHeatmapSnapshot(
            createdTodos: nil,
            completedTodos: nil,
            deletedTodos: nil,
            quarterStart: nil,
            now: now
        )
    }

    func restoreTodoSnapshot(
        todoId: String,
        now: Date = Date()
    ) {
        lock.lock()
        if let todo = sourceTodo(id: todoId) {
            upsertTodaySource(todo.withDeletedAt(nil))
        }
        if let todo = sourceTodo(id: todoId) {
            upsertHeatmapSource(todo.withDeletedAt(nil))
        }
        lock.unlock()

        updateTodaySnapshot(todos: nil, now: now)
        updateHeatmapSnapshot(
            createdTodos: nil,
            completedTodos: nil,
            deletedTodos: nil,
            quarterStart: nil,
            now: now
        )
    }

    func clear() {
        lock.lock()
        source = SnapshotSource()
        lock.unlock()

        snapshotStore.clearSnapshots()
        preferenceStore.clear()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

private extension WidgetSnapshotUpdaterImpl {
    private func updateTodaySource(
        _ todos: [WidgetTodoSnapshot]?
    ) -> [WidgetTodoSnapshot]? {
        lock.lock()
        defer { lock.unlock() }

        if let todos {
            source.hasTodaySource = true
            source.todayTodos = todos
        }

        guard source.hasTodaySource else { return nil }
        return source.todayTodos
    }

    private func updateHeatmapSource(
        createdTodos: [WidgetTodoSnapshot]?,
        completedTodos: [WidgetTodoSnapshot]?,
        deletedTodos: [WidgetTodoSnapshot]?,
        quarterStart: Date?
    ) -> SnapshotSource? {
        lock.lock()
        defer { lock.unlock() }

        if let createdTodos,
           let completedTodos,
           let deletedTodos,
           let quarterStart {
            source.hasHeatmapSource = true
            source.createdTodos = createdTodos
            source.completedTodos = completedTodos
            source.deletedTodos = deletedTodos
            source.quarterStart = quarterStart
        }

        guard source.hasHeatmapSource,
              source.quarterStart != nil else { return nil }
        return source
    }

    func upsertTodaySource(_ todo: WidgetTodoSnapshot) {
        guard source.hasTodaySource else { return }

        source.todayTodos.removeAll { $0.id == todo.id }

        guard todo.deletedAt == nil,
              todo.completedAt == nil else { return }

        source.todayTodos.append(todo)
    }

    func upsertHeatmapSource(_ todo: WidgetTodoSnapshot) {
        guard source.hasHeatmapSource else { return }

        source.createdTodos.upsert(todo)
        if todo.completedAt == nil {
            source.completedTodos.removeAll { $0.id == todo.id }
        } else {
            source.completedTodos.upsert(todo)
        }

        if todo.deletedAt == nil {
            source.deletedTodos.removeAll { $0.id == todo.id }
        } else {
            source.deletedTodos.upsert(todo)
        }
    }

    func sourceTodo(id: String) -> WidgetTodoSnapshot? {
        source.todayTodos.first { $0.id == id }
            ?? source.createdTodos.first { $0.id == id }
            ?? source.completedTodos.first { $0.id == id }
            ?? source.deletedTodos.first { $0.id == id }
    }
}

private extension Array where Element == WidgetTodoSnapshot {
    mutating func upsert(_ todo: WidgetTodoSnapshot) {
        removeAll { $0.id == todo.id }
        append(todo)
    }
}

private extension WidgetTodoSnapshot {
    func withDeletedAt(_ deletedAt: Date?) -> Self {
        WidgetTodoSnapshot(
            id: id,
            number: number,
            title: title,
            isPinned: isPinned,
            createdAt: createdAt,
            completedAt: completedAt,
            deletedAt: deletedAt,
            dueDate: dueDate
        )
    }
}
