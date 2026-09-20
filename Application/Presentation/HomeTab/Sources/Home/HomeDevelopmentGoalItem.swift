//
//  HomeDevelopmentGoalItem.swift
//  HomeTab
//
//  Created by opfic on 9/20/26.
//

import Domain

struct HomeDevelopmentGoalItem: Equatable, Identifiable {
    let goal: DevelopmentGoal
    let recentRecord: DevelopmentRecord.Version?

    var id: String { goal.id }
}
