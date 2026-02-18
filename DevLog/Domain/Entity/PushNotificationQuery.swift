//
//  PushNotificationQuery.swift
//  DevLog
//
//  Created by opfic on 2/18/26.
//

import Foundation

struct PushNotificationQuery: Equatable {
    enum SortOrder: Equatable {
        case latest
        case oldest
    }

    enum TimeFilter: Equatable {
        case none
        case hours(Int)
        case days(Int)
    }

    var sortOrder: SortOrder
    var timeFilter: TimeFilter
    var unreadOnly: Bool
    var pageSize: Int

    static let `default` = PushNotificationQuery(
        sortOrder: .latest,
        timeFilter: .none,
        unreadOnly: false,
        pageSize: 20
    )
}

extension PushNotificationQuery.TimeFilter {
    var thresholdDate: Date? {
        switch self {
        case .none:
            return nil
        case .hours(let value):
            return Date().addingTimeInterval(-Double(value) * 3600.0)
        case .days(let value):
            return Date().addingTimeInterval(-Double(value) * 86400.0)
        }
    }
}
