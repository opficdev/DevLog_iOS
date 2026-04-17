//
//  HeatmapQuarter.swift
//  DevLog
//
//  Created by opfic on 3/2/26.
//

import Foundation

struct HeatmapQuarter: Identifiable, Hashable {
    var id: Date { quarterStart }
    let quarterStart: Date
    let months: [HeatmapMonth]
}
