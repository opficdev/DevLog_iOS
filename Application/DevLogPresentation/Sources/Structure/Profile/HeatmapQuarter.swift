//
//  HeatmapQuarter.swift
//  DevLogPresentation
//
//  Created by opfic on 3/2/26.
//

import Foundation
import DevLogDomain

public struct HeatmapQuarter: Identifiable, Hashable {
    public var id: Date { quarterStart }
    public let quarterStart: Date
    public let months: [HeatmapMonth]
}
