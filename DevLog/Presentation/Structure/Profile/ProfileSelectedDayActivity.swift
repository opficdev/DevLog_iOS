//
//  ProfileSelectedDayActivity.swift
//  DevLog
//
//  Created by opfic on 3/2/26.
//

import Foundation

struct ProfileSelectedDayActivity: Identifiable, Hashable {
    let todo: Todo
    let showsCreated: Bool
    let showsCompleted: Bool

    var id: String { todo.id }

    var activityLabel: String {
        if showsCreated && showsCompleted {
            return String(localized: "profile_activity_created_completed")
        }
        return showsCreated
            ? String(localized: "profile_activity_created")
            : String(localized: "profile_activity_completed")
    }
}
