//
//  ProfileHeatmapWidgetProvider.swift
//  DevLogWidget
//
//  Created by opfic on 4/15/26.
//

import AppIntents
import WidgetKit

struct ProfileHeatmapWidgetProvider: AppIntentTimelineProvider {
    typealias Intent = ProfileHeatmapWidgetConfigurationIntent

    func placeholder(in context: Context) -> ProfileHeatmapWidgetEntry {
        .init(date: .now)
    }

    func snapshot(
        for configuration: ProfileHeatmapWidgetConfigurationIntent,
        in context: Context
    ) async -> ProfileHeatmapWidgetEntry {
        .init(date: .now)
    }

    func timeline(
        for configuration: ProfileHeatmapWidgetConfigurationIntent,
        in context: Context
    ) async -> Timeline<ProfileHeatmapWidgetEntry> {
        Timeline(
            entries: [.init(date: .now)],
            policy: .never
        )
    }
}
