//
//  ProfileSelectedDayActivity.swift
//  DevLog
//
//  Created by opfic on 3/2/26.
//

import Foundation

struct ProfileSelectedDayActivity: Identifiable, Hashable, Comparable {
    var id: String { todoId }
    let todoId: String
    let title: String
    let number: Int
    let category: TodoCategory
    let activityKinds: [ActivityKind]

    var isDeleted: Bool {
        activityKinds.contains(.deleted)
    }

    var activityKindItems: [ActivityKindItem] {
        let orderedKinds: [ActivityKind] = [.created, .completed, .deleted]
        return orderedKinds.compactMap { activityKind in
            if activityKinds.contains(activityKind) {
                return ActivityKindItem(from: activityKind)
            }
            return nil
        }
    }

    static func < (lhs: ProfileSelectedDayActivity, rhs: ProfileSelectedDayActivity) -> Bool {
        lhs.number < rhs.number
    }
}
