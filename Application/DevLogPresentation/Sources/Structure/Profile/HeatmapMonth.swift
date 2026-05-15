//
//  HeatmapMonth.swift
//  DevLog
//
//  Created by opfic on 3/2/26.
//

import Foundation
import DevLogDomain

public struct HeatmapMonth: Identifiable, Hashable {
    public var id: Date { monthStart }
    public let monthStart: Date
    public let weeks: [[HeatmapDay]]
}
