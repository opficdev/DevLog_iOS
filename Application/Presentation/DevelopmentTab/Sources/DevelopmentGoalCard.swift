//
//  DevelopmentGoalCard.swift
//  DevelopmentTab
//
//  Created by opfic on 10/5/26.
//

import Development
import Domain
import PresentationShared
import SwiftUI

struct DevelopmentGoalCard: View {
    let goal: DevelopmentGoal
    let recentRecord: DevelopmentGoalListFeature.RecentRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text(goal.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                GoalStatusBadge(status: goal.status)
            }
            if !goal.description.isEmpty {
                Text(goal.description)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if case .loaded(let version?) = recentRecord {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundStyle(Color.textTertiary)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String.localizedStringWithFormat(
                            String(localized: "development_goals_recent_record_format", bundle: PresentationResources.bundle),
                            version.title
                        ))
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                        TimelineView(.periodic(from: .now, by: 1.0)) { context in
                            Text(String.localizedStringWithFormat(
                                String(localized: "development_goals_recent_record_date_format", bundle: PresentationResources.bundle),
                                RelativeTime.text(from: version.confirmedAt, now: context.date),
                                version.confirmedAt.formatted(.dateTime.month().day().hour().minute()),
                                RecordPresentation.versionLabel(version.number)
                            ))
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                            .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(Color.appBackground, in: .rect(cornerRadius: 12))
            }
        }
        .padding(18)
        .background(Color.surface, in: .rect(cornerRadius: 24))
        .contentShape(.rect)
    }
}
