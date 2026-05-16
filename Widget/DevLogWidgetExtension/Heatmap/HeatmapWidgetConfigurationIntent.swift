//
//  HeatmapWidgetConfigurationIntent.swift
//  DevLogWidgetExtension
//
//  Created by opfic on 4/15/26.
//

import AppIntents
import WidgetKit

struct HeatmapWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget_heatmap_title"
    static var description = IntentDescription("widget_heatmap_description")
}
