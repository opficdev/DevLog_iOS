//
//  ProfileSelectedDayActivity.swift
//  DevLog
//
//  Created by opfic on 3/2/26.
//

import Foundation

struct ProfileSelectedDayActivity: Identifiable, Hashable {
    var id: String { todo.id }
    let todo: Todo
    let kind: ProfileActivityKind
}
