//
//  HeatmapActivityItem.swift
//  DevLog
//
//  Created by opfic on 3/2/26.
//

import Foundation
import DevLogDomain
import DevLogData

public struct HeatmapActivityItem: Identifiable, Hashable, Comparable {
    public var id: String { todoId }
    public let todoId: String
    public let title: String
    public let number: Int
    public let category: TodoCategory
    public let activityKinds: [ActivityKind]
    public let isDeleted: Bool

    public var activityKindItems: [ActivityKindItem] {
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

    public static func < (lhs: HeatmapActivityItem, rhs: HeatmapActivityItem) -> Bool {
        lhs.number < rhs.number
    }
}
