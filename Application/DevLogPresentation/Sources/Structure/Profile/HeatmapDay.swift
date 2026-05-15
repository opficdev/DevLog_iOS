//
//  HeatmapDay.swift
//  DevLog
//
//  Created by opfic on 3/2/26.
//

import Foundation
import DevLogDomain
import DevLogData

public struct HeatmapDay: Hashable {
    public let date: Date
    public let createdCount: Int
    public let completedCount: Int
    public let deletedCount: Int
    public let isVisible: Bool
}
