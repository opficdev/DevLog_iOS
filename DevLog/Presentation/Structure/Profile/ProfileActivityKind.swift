//
//  ProfileActivityKind.swift
//  DevLog
//
//  Created by 최윤진 on 4/3/26.
//

import SwiftUI

enum ProfileActivityKind: String, CaseIterable, Hashable {
    case created
    case completed
    case deleted

    static var selectableKinds: [ProfileActivityKind] {
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

    var badgeColor: Color {
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
