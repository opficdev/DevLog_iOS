//
//  HeatmapWidget.swift
//  DevLogWidget
//
//  Created by opfic on 4/15/26.
//

import SwiftUI
import AppIntents
import WidgetKit

struct HeatmapWidget: Widget {
    let kind = WidgetKind.heatmap

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: HeatmapWidgetConfigurationIntent.self,
            provider: HeatmapWidgetProvider()
        ) { entry in
            HeatmapWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(WidgetDeepLink.heatmapURL)
        }
        .configurationDisplayName("Heatmap")
        .description("widget_heatmap_description")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
