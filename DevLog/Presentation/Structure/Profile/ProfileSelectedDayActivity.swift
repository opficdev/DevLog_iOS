//
//  ProfileSelectedDayActivity.swift
//  DevLog
//
//  Created by opfic on 3/2/26.
//

import SwiftUI

enum ProfileActivityKind: String, CaseIterable, Hashable {
    case created
    case completed
    case deleted

    static var heatmapSelectableKinds: [ProfileActivityKind] {
        [.created, .completed]
    }

    var title: String {
        switch self {
        case .created:
            return String(localized: "profile_activity_created")
        case .completed:
            return String(localized: "profile_activity_completed")
        case .deleted:
            return String(localized: "profile_activity_deleted")
        }
    }

    var foregroundColor: Color {
        switch self {
        case .created:
            return .orange
        case .completed:
            return .blue
        case .deleted:
            return .red
        }
    }
}

struct ProfileSelectedDayActivity: Identifiable, Hashable {
    var id: String { todo.id }
    let todo: Todo
    let kind: ProfileActivityKind

    var activityBadge: ProfileActivityBadge {
        ProfileActivityBadge(kind: kind)
    }
}

struct ProfileActivityBadge: Identifiable {
    let kind: ProfileActivityKind

    var id: String { kind.rawValue }
    var title: String { kind.title }
    var foregroundColor: Color { kind.foregroundColor }
}
