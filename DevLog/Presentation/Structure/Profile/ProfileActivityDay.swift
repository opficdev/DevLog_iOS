//
//  ProfileActivityDay.swift
//  DevLog
//
//  Created by opfic on 3/2/26.
//

import Foundation

struct ProfileActivityDay: Hashable {
    let date: Date
    let createdCount: Int
    let completedCount: Int
    let deletedCount: Int
    let isVisible: Bool
}
