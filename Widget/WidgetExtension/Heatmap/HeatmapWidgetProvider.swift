//
//  HeatmapWidgetProvider.swift
//  WidgetExtension
//
//  Created by opfic on 4/15/26.
//

import AppIntents
import WidgetKit

struct HeatmapWidgetProvider: AppIntentTimelineProvider {
    typealias Intent = HeatmapWidgetConfigurationIntent
    typealias Entry = HeatmapWidgetEntry
    private let store = WidgetSnapshotStore()

    // 위젯 갤러리나 로딩 전 상태에서 즉시 표시할 기본 엔트리.
    func placeholder(in context: Context) -> HeatmapWidgetEntry {
        .init(date: .now, snapshot: nil)
    }

    // 현재 시점의 단일 스냅샷을 만들어 미리보기와 일시적인 렌더링에 사용한다.
    func snapshot(
        for configuration: HeatmapWidgetConfigurationIntent,
        in context: Context
    ) async -> HeatmapWidgetEntry {
        let snapshot = try? store.loadHeatmapSnapshot()
        return .init(
            date: .now,
            snapshot: snapshot
        )
    }

    // 실제 위젯이 사용할 타임라인 엔트리를 구성한다.
    // 현재 단계에서는 저장된 스냅샷 하나만 내려주고, 갱신은 앱이 별도로 트리거한다.
    func timeline(
        for configuration: HeatmapWidgetConfigurationIntent,
        in context: Context
    ) async -> Timeline<HeatmapWidgetEntry> {
        let snapshot = try? store.loadHeatmapSnapshot()
        let entries: [HeatmapWidgetEntry] = [
            .init(
                date: .now,
                snapshot: snapshot
            )
        ]

        return Timeline(
            entries: entries,
            policy: .never
        )
    }
}
