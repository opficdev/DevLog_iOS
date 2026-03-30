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
            return "생성/완료"
        }
        return showsCreated ? "생성" : "완료"
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.todo.id == rhs.todo.id
            && lhs.showsCreated == rhs.showsCreated
            && lhs.showsCompleted == rhs.showsCompleted
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(todo.id)
        hasher.combine(showsCreated)
        hasher.combine(showsCompleted)
    }
}
