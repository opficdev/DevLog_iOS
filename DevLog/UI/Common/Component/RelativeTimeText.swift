//
//  RelativeTimeText.swift
//  DevLog
//
//  Created by opfic on 3/25/26.
//

import SwiftUI

struct RelativeTimeText: View {
    let date: Date
    var bodyFont: Font = .caption2
    var bodyColor: Color = .gray

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            Text(relativeTimeText(from: date, now: context.date) + " 업데이트")
                .font(bodyFont)
                .foregroundStyle(bodyColor)
        }
    }

    private func relativeTimeText(from date: Date, now: Date) -> String {
        let seconds = Int(now.timeIntervalSince(date))

        if seconds < 60 {
            return "\(max(0, seconds))초 전"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)분 전"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)시간 전"
        } else {
            let days = seconds / 86400
            return "\(days)일 전"
        }
    }
}
