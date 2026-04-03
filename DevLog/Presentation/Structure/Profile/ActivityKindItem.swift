//
//  ActivityKindItem.swift
//  DevLog
//
//  Created by opfic on 4/4/26.
//

import SwiftUI

struct ActivityKindItem: Identifiable, Hashable {
    private let activityKind: ActivityKind

    init(from activityKind: ActivityKind) {
        self.activityKind = activityKind
    }

    static var selectableItems: [ActivityKindItem] {[
        .init(from: .created), .init(from: .completed) ]
    }

    var id: String { activityKind.rawValue }

    var rawValue: String { activityKind.rawValue }

    var title: String {
        switch activityKind {
        case .created:
            return String(localized: "profile_activity_created")
        case .completed:
            return String(localized: "profile_activity_completed")
        case .deleted:
            return String(localized: "profile_activity_deleted")
        }
    }

    var badgeColor: Color {
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
