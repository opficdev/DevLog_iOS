//
//  ActivityKindItem.swift
//  DevLogPresentation
//
//  Created by opfic on 4/4/26.
//

import SwiftUI
import DevLogCore

public struct ActivityKindItem: Identifiable, Hashable {
    private let activityKind: ActivityKind

    public init(from activityKind: ActivityKind) {
        self.activityKind = activityKind
    }

    public static let created = ActivityKindItem(from: .created)
    public static let completed = ActivityKindItem(from: .completed)
    public static let deleted = ActivityKindItem(from: .deleted)

    public static var selectableItems: [ActivityKindItem] {[
        .created, .completed, .deleted ]
    }

    public var id: String { activityKind.rawValue }

    public var rawValue: String { activityKind.rawValue }

    public var title: String {
        switch activityKind {
        case .created:
            return String(localized: "profile_activity_created")
        case .completed:
            return String(localized: "profile_activity_completed")
        case .deleted:
            return String(localized: "profile_activity_deleted")
        }
    }

    public var badgeColor: Color {
        switch activityKind {
        case .created:
            return .orange
        case .completed:
            return .blue
        case .deleted:
            return .red
        }
    }
}
