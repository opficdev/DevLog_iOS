//
//  ProfileActivityType.swift
//  DevLog
//
//  Created by opfic on 3/2/26.
//

import Foundation

enum ProfileActivityType: String, CaseIterable, Hashable {
    case created
    case completed

    var title: String {
        switch self {
        case .created: return String(localized: "profile_activity_created")
        case .completed: return String(localized: "profile_activity_completed")
        }
    }
}
