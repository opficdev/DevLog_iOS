//
//  TodayDisplayOptions.swift
//  DevLog
//
//  Created by opfic on 3/6/26.
//

import Foundation

struct TodayDisplayOptions: Equatable {
    enum DueDateVisibility: String, CaseIterable, Equatable {
        case all
        case withDueDateOnly
        case withoutDueDateOnly
    }

    enum FocusVisibility: String, CaseIterable, Equatable {
        case all
        case focusedOnly
    }

    var dueDateVisibility: DueDateVisibility
    var focusVisibility: FocusVisibility

    static let `default` = TodayDisplayOptions(
        dueDateVisibility: .all,
        focusVisibility: .all
    )
}
