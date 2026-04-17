//
//  HeatmapWidgetConfigurationIntent.swift
//  DevLogWidget
//
//  Created by opfic on 4/15/26.
//

import AppIntents
import WidgetKit

struct HeatmapWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Heatmap"
    static var description = IntentDescription("이번 달 활동 히트맵을 표시합니다.")
}
