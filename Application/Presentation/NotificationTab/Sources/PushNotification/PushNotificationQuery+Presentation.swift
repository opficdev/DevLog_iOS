//
//  PushNotificationQuery+Presentation.swift
//  Presentation
//
//  Created by opfic on 6/17/26.
//

import Core
import Foundation

public extension PushNotificationQuery.SortOrder {
    var title: String {
        switch self {
        case .latest:
            return String(localized: "push_sort_latest")
        case .oldest:
            return String(localized: "push_sort_oldest")
        }
    }
}

public extension PushNotificationQuery.TimeFilter {
    var title: String {
        switch self {
        case .none:
            return String(localized: "push_timefilter_all")
        case .hours(let value):
            return String.localizedStringWithFormat(
                String(localized: "push_timefilter_hours_format"),
                Int64(value)
            )
        case .days(let value):
            return String.localizedStringWithFormat(
                String(localized: "push_timefilter_days_format"),
                Int64(value)
            )
        }
    }

    static var availableOptions: [PushNotificationQuery.TimeFilter] { [
        .none,
        .hours(1),
        .hours(6),
        .hours(12),
        .days(1),
        .days(7),
        .days(30)
    ] }
}
