//
//  DevelopmentGoalStatus+Presentation.swift
//  DevelopmentTab
//
//  Created by opfic on 10/5/26.
//

import Domain
import PresentationShared
import SwiftUI

extension DevelopmentGoal.Status {
    static let tabs = [Self.inProgress, .completed, .archived]

    var emptyTitle: String {
        switch self {
        case .inProgress:
            String(localized: "development_goals_empty_in_progress", bundle: PresentationResources.bundle)
        case .completed:
            String(localized: "development_goals_empty_completed", bundle: PresentationResources.bundle)
        case .archived:
            String(localized: "development_goals_empty_archived", bundle: PresentationResources.bundle)
        }
    }
}
