//
//  ProfileCompletionQuarter.swift
//  DevLog
//
//  Created by opfic on 3/2/26.
//

import Foundation

struct ProfileCompletionQuarter: Identifiable, Hashable {
    var id: Date { quarterStart }
    let quarterStart: Date
    let months: [ProfileCompletionMonth]
    var maxCount: Int {
        months
            .flatMap { $0.weeks }
            .flatMap { $0 }
            .filter { $0.isInMonth }
            .map { $0.createdCount + $0.completedCount }
            .max() ?? 0
    }
}
