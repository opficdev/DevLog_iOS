//
//  HeatmapActivityItem.swift
//  DevLog
//
//  Created by opfic on 3/2/26.
//

import Foundation

struct HeatmapActivityItem: Identifiable, Hashable, Comparable {
    var id: String { todoId }
    let todoId: String
    let title: String
    let number: Int
    let category: TodoCategory
    let activityKinds: [ActivityKind]
    let isDeleted: Bool

    var activityKindItems: [ActivityKindItem] {
        let orderedKinds: [ActivityKind] = [.created, .completed, .deleted]
        return orderedKinds.compactMap { activityKind in
            if activityKinds.contains(activityKind) {
                return ActivityKindItem(from: activityKind)
            }
            return nil
        }
    }

    init?(todo: Todo, activityKinds: [ActivityKind]) {
        guard let number = todo.number else { return nil }
        self.todoId = todo.id
        self.title = todo.title
        self.number = number
        self.category = todo.category
        self.activityKinds = activityKinds
        self.isDeleted = todo.deletedAt != nil
    }

    static func < (lhs: HeatmapActivityItem, rhs: HeatmapActivityItem) -> Bool {
        lhs.number < rhs.number
    }
}
