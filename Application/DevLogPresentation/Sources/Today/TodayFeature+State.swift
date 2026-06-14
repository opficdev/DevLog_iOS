//
//  TodayFeature+State.swift
//  DevLogPresentation
//
//  Created by opfic on 6/14/26.
//

import Foundation

extension TodayFeature.State {
    func summaryValue(for scope: TodayFeature.SectionScope) -> Int {
        switch scope {
        case .all:
            return displayedTodos.count
        case .focused:
            return displayedTodos.filter(\.isPinned).count
        case .overdue:
            return displayedTodos.filter(isOverdue).count
        case .dueSoon:
            return displayedTodos.filter(isDueSoon).count
        }
    }

    var displayedTodos: [TodayTodoItem] {
        let dueDateFilteredTodos: [TodayTodoItem]
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

    func groupedSectionItems(
        from items: [TodayTodoItem]
    ) -> TodayFeature.SectionCollection {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        guard let windowEnd = calendar.date(
            byAdding: .day,
            value: TodayFeature.upcomingWindowDays,
            to: startOfToday
        ) else {
            return TodayFeature.SectionCollection(
                focused: items.filter(\.isPinned),
                unscheduled: items.filter { !$0.isPinned && $0.dueDate == nil }
            )
        }

        var collection = TodayFeature.SectionCollection()

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

    func isOverdue(_ item: TodayTodoItem) -> Bool {
        guard let dueDate = item.dueDate else { return false }
        let calendar = Calendar.current
        return calendar.startOfDay(for: dueDate) < calendar.startOfDay(for: Date())
    }

    func isDueSoon(_ item: TodayTodoItem) -> Bool {
        guard let dueDate = item.dueDate else { return false }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        guard let windowEnd = calendar.date(
            byAdding: .day,
            value: TodayFeature.upcomingWindowDays,
            to: startOfToday
        ) else {
            return false
        }
        let dueDay = calendar.startOfDay(for: dueDate)
        return startOfToday <= dueDay && dueDay <= windowEnd
    }

    func makeSection(
        category: TodayFeature.SectionCategory,
        title: String,
        items: [TodayTodoItem]
    ) -> [TodayFeature.SectionContent] {
        guard !items.isEmpty else { return [] }
        return [TodayFeature.SectionContent(category: category, title: title, items: items)]
    }
}
