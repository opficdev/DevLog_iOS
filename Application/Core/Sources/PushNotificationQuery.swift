//
//  PushNotificationQuery.swift
//  Core
//
//  Created by opfic on 2/18/26.
//

import Foundation

public struct PushNotificationQuery: Equatable {
    public enum SortOrder: Equatable {
        case latest
        case oldest
    }

    public enum TimeFilter: Equatable, Hashable {
        case none
        case hours(Int)
        case days(Int)
    }

    public var sortOrder: SortOrder
    public var timeFilter: TimeFilter
    public var unreadOnly: Bool
    public var pageSize: Int

    public init(
        sortOrder: SortOrder,
        timeFilter: TimeFilter,
        unreadOnly: Bool,
        pageSize: Int
    ) {
        self.sortOrder = sortOrder
        self.timeFilter = timeFilter
        self.unreadOnly = unreadOnly
        self.pageSize = pageSize
    }

    public static let `default` = PushNotificationQuery(
        sortOrder: .latest,
        timeFilter: .none,
        unreadOnly: false,
        pageSize: 20
    )
}

public extension PushNotificationQuery.TimeFilter {
    var id: String {
        switch self {
        case .none: return "none"
        case .hours(let value): return "hours-\(value)"
        case .days(let value): return "days-\(value)"
        }
    }

    init(id: String) {
        if id == "none" {
            self = .none
        } else if id.hasPrefix("hours-") {
            let value = Int(id.replacingOccurrences(of: "hours-", with: "")) ?? 0
            self = 0 < value ? .hours(value) : .none
        } else if id.hasPrefix("days-") {
            let value = Int(id.replacingOccurrences(of: "days-", with: "")) ?? 0
            self = 0 < value ? .days(value) : .none
        } else {
            self = .none
        }
    }

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
