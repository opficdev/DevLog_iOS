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
        }
        .configurationDisplayName("Heatmap")
        .description("활동 히트맵을 표시합니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
