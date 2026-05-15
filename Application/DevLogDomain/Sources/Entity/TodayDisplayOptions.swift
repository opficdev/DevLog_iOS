//
//  TodayDisplayOptions.swift
//  DevLog
//
//  Created by opfic on 3/6/26.
//

import Foundation

public struct TodayDisplayOptions: Equatable {
    public enum DueDateVisibility: String, CaseIterable, Equatable {
        case all
        case withDueDateOnly
        case withoutDueDateOnly
    }

    public enum FocusVisibility: String, CaseIterable, Equatable {
        case all
        case focusedOnly
    }

    public var dueDateVisibility: DueDateVisibility
    public var focusVisibility: FocusVisibility

    public init(
        dueDateVisibility: DueDateVisibility,
        focusVisibility: FocusVisibility
    ) {
        self.dueDateVisibility = dueDateVisibility
        self.focusVisibility = focusVisibility
    }

    public static let `default` = TodayDisplayOptions(
        dueDateVisibility: .all,
        focusVisibility: .all
    )
}
