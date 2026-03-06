//
//  ProfileWeeklyTrendPoint.swift
//  DevLog
//
//  Created by opfic on 3/6/26.
//

import Foundation

struct ProfileWeeklyTrendPoint: Identifiable, Hashable {
    var id: Date { weekStart }
    let weekStart: Date
    let weekIndex: Int
    let createdCount: Int
    let completedCount: Int

    func count(for activityType: ProfileActivityType) -> Int {
        switch activityType {
        case .created:
            createdCount
        case .completed:
            completedCount
        }
    }
}
