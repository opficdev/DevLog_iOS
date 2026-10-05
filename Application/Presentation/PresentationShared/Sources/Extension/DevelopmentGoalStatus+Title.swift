//
//  DevelopmentGoalStatus+Title.swift
//  PresentationShared
//
//  Created by opfic on 10/5/26.
//

import Domain
import Foundation

public extension DevelopmentGoal.Status {
    var title: String {
        switch self {
        case .inProgress:
            String(localized: "development_goal_status_in_progress", bundle: PresentationResources.bundle)
        case .completed:
            String(localized: "development_goal_status_completed", bundle: PresentationResources.bundle)
        case .archived:
            String(localized: "development_goal_status_archived", bundle: PresentationResources.bundle)
        }
    }
}
