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
}
