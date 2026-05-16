//
//  TodayWidgetSnapshotFactory.swift
//  DevLogWidgetCore
//
//  Created by opfic on 4/17/26.
//

import Foundation
import DevLogDomain
import DevLogData

public struct TodayWidgetSnapshotFactory {
    private enum SectionCategory: String, CaseIterable {
        case focused
        case overdue
        case dueSoon
        case later
        case unscheduled
    }

    private struct SectionCollection {
        var focused = [TodayWidgetTodoItem]()
        var overdue = [TodayWidgetTodoItem]()
        var dueSoon = [TodayWidgetTodoItem]()
        var later = [TodayWidgetTodoItem]()
        var unscheduled = [TodayWidgetTodoItem]()

        func items(for category: SectionCategory) -> [TodayWidgetTodoItem] {
            switch category {
            case .focused:
                focused
            case .overdue:
                overdue
            case .dueSoon:
                dueSoon
            case .later:
                later
            case .unscheduled:
                unscheduled
            }
        }
    }

    private struct TodayWidgetTodoItem {
        let id: String
        let number: Int
        let title: String
        let isPinned: Bool
        let dueDate: Date?

        init?(from todo: Todo) {
            guard let number = todo.number else { return nil }
            self.id = todo.id
            self.number = number
            self.title = todo.title
            self.isPinned = todo.isPinned
            self.dueDate = todo.dueDate
        }
    }

    private let calendar: Calendar
    private let upcomingWindowDays: Int

    public init(
        calendar: Calendar = .current,
        upcomingWindowDays: Int = 7
    ) {
        self.calendar = calendar
        self.upcomingWindowDays = upcomingWindowDays
    }

    public func makeSnapshot(
        todos: [Todo],
        displayOptions: TodayDisplayOptions,
        now: Date = Date()
    ) -> TodayWidgetSnapshot {
        let todayWidgetTodoItems = todos.compactMap { TodayWidgetTodoItem(from: $0) }
        let displayedTodos = displayedTodos(
            from: todayWidgetTodoItems,
            displayOptions: displayOptions
        )
        let sections = groupedSectionItems(
            from: displayedTodos,
            now: now
        )

        return TodayWidgetSnapshot(
            generatedAt: now,
            totalCount: displayedTodos.count,
            focusedCount: displayedTodos.filter(\.isPinned).count,
            overdueCount: displayedTodos.filter { isOverdue($0, now: now) }.count,
            dueSoonCount: displayedTodos.filter { isDueSoon($0, now: now) }.count,
            sections: SectionCategory.allCases.compactMap { category in
                let items = sections.items(for: category)
                guard !items.isEmpty else { return nil }

                return TodayWidgetSectionSnapshot(
                    category: category.rawValue,
                    items: items.map {
                        WidgetTodoSnapshotItem(
                            id: $0.id,
                            number: $0.number,
                            title: $0.title,
                            isPinned: $0.isPinned,
                            dueDate: $0.dueDate
                        )
                    }
                )
            }
        )
    }

    private func displayedTodos(
        from todos: [TodayWidgetTodoItem],
        displayOptions: TodayDisplayOptions
    ) -> [TodayWidgetTodoItem] {
        let dueDateFilteredTodos: [TodayWidgetTodoItem]
        switch displayOptions.dueDateVisibility {
        case .all:
            dueDateFilteredTodos = todos
        case .withDueDateOnly:
            dueDateFilteredTodos = todos.filter { $0.dueDate != nil }
        case .withoutDueDateOnly:
            dueDateFilteredTodos = todos.filter { $0.dueDate == nil }
        }

        switch displayOptions.focusVisibility {
        case .all:
            return dueDateFilteredTodos
        case .focusedOnly:
            return dueDateFilteredTodos.filter(\.isPinned)
        }
    }

    private func groupedSectionItems(
        from items: [TodayWidgetTodoItem],
        now: Date
    ) -> SectionCollection {
        let startOfToday = calendar.startOfDay(for: now)
        guard let windowEnd = calendar.date(
            byAdding: .day,
            value: upcomingWindowDays,
            to: startOfToday
        ) else {
            return SectionCollection(
                focused: items.filter(\.isPinned),
                unscheduled: items.filter { !$0.isPinned && $0.dueDate == nil }
            )
        }

        var collection = SectionCollection()

        for item in items {
            if item.isPinned {
                collection.focused.append(item)
                continue
            }

            guard let dueDate = item.dueDate else {
                collection.unscheduled.append(item)
                continue
            }

            let dueDay = calendar.startOfDay(for: dueDate)
            if dueDay < startOfToday {
                collection.overdue.append(item)
            } else if dueDay <= windowEnd {
                collection.dueSoon.append(item)
            } else {
                collection.later.append(item)
            }
        }

        return collection
    }

    private func isOverdue(
        _ item: TodayWidgetTodoItem,
        now: Date
    ) -> Bool {
        guard let dueDate = item.dueDate else { return false }
        return calendar.startOfDay(for: dueDate) < calendar.startOfDay(for: now)
    }

    private func isDueSoon(
        _ item: TodayWidgetTodoItem,
        now: Date
    ) -> Bool {
        guard let dueDate = item.dueDate else { return false }
        let startOfToday = calendar.startOfDay(for: now)
        guard let windowEnd = calendar.date(
            byAdding: .day,
            value: upcomingWindowDays,
            to: startOfToday
        ) else {
            return false
        }

        let dueDay = calendar.startOfDay(for: dueDate)
        return startOfToday <= dueDay && dueDay <= windowEnd
    }
}
