//
//  ProfileHeatmapWidget.swift
//  DevLogWidget
//
//  Created by opfic on 4/15/26.
//

import SwiftUI
import AppIntents
import WidgetKit

struct ProfileHeatmapWidget: Widget {
    let kind = "ProfileHeatmapWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ProfileHeatmapWidgetConfigurationIntent.self,
            provider: ProfileHeatmapWidgetProvider()
        ) { _ in
            ProfileHeatmapWidgetEntryView()
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Profile Heatmap")
        .description("이번 달 활동 히트맵을 표시합니다.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
