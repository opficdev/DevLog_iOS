//
//  ProfileCompletionDay.swift
//  DevLog
//
//  Created by opfic on 3/2/26.
//

import Foundation

struct ProfileCompletionDay: Hashable {
    let date: Date
    let createdCount: Int
    let completedCount: Int
    let isInMonth: Bool
}
