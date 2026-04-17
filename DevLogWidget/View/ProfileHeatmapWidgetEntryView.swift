//
//  ProfileHeatmapWidgetEntryView.swift
//  DevLogWidget
//
//  Created by opfic on 4/15/26.
//

import SwiftUI
import WidgetKit

struct ProfileHeatmapWidgetEntryView: View {
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이번 달 히트맵")
                .font(.headline)

            Spacer()

            if widgetFamily == .systemSmall {
                Text("앱을 열어\n히트맵을 준비하세요")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                WidgetPlaceholderCard(
                    title: "이번 달 히트맵",
                    message: "데이터 연결 전"
                )
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
