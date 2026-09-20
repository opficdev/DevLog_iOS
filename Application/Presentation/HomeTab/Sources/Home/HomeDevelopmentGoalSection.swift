//
//  HomeDevelopmentGoalSection.swift
//  HomeTab
//
//  Created by opfic on 9/20/26.
//

import SwiftUI
import PresentationShared

struct HomeDevelopmentGoalSection: View {
    let items: [HomeDevelopmentGoalItem]
    let isLoading: Bool
    let hasLoaded: Bool
    let hasLoadFailure: Bool
    let onCreate: () -> Void
    let onSelect: (HomeDevelopmentGoalItem) -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            content
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var content: some View {
        if !hasLoaded && isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
        } else if !hasLoaded && hasLoadFailure {
            ContentUnavailableView {
                Label(
                    String(localized: "common_error_title", bundle: PresentationResources.bundle),
                    systemImage: "exclamationmark.triangle"
                )
            } description: {
                Text(String(localized: "common_error_message", bundle: PresentationResources.bundle))
            } actions: {
                Button(String(localized: "development_record_timeline_retry", bundle: PresentationResources.bundle)) {
                    onRetry()
                }
                .buttonStyle(.borderedProminent)
            }
        } else if items.isEmpty {
            ContentUnavailableView {
                Label(
                    String(
                        localized: "home_development_goal_empty_title",
                        bundle: PresentationResources.bundle
                    ),
                    systemImage: "flag.checkered"
                )
            } description: {
                Text(
                    String(
                        localized: "home_development_goal_empty_message",
                        bundle: PresentationResources.bundle
                    )
                )
            }
        } else {
            LazyVStack(spacing: 16) {
                ForEach(items) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        HomeDevelopmentGoalCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("home_development_goal_section_title", bundle: PresentationResources.bundle)
                .font(.title2)
                .foregroundStyle(Color.primary)
            if hasLoaded {
                Text(
                    String.localizedStringWithFormat(
                        String(localized: "home_development_goal_count_format", bundle: PresentationResources.bundle),
                        items.count
                    )
                )
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.accent.opacity(0.1), in: .capsule)
            }
            Spacer()
            Button(action: onCreate) {
                Text("home_development_goal_create", bundle: PresentationResources.bundle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
            }
            .accessibilityLabel(
                String(localized: "development_goal_create_title", bundle: PresentationResources.bundle)
            )
        }
        .accessibilityElement(children: .combine)
    }
}

private struct HomeDevelopmentGoalCard: View {
    let item: HomeDevelopmentGoalItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                HomeDevelopmentGoalStatusBadge()
                Spacer(minLength: 12)
                if let recentRecord = item.recentRecord {
                    Text(recentRecord.confirmedAt, format: .dateTime.month().day().hour().minute())
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }
            }

            Text(item.goal.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !item.goal.description.isEmpty {
                Text(item.goal.description)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            if let recentRecord = item.recentRecord {
                VStack(alignment: .leading, spacing: 3) {
                    Text("home_development_goal_recent_record", bundle: PresentationResources.bundle)
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                    Text(recentRecord.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                }
            } else {
                Text("development_record_empty_title", bundle: PresentationResources.bundle)
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(18)
        .background(Color.surface, in: .rect(cornerRadius: 24))
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

private struct HomeDevelopmentGoalStatusBadge: View {
    var body: some View {
        Label {
            Text("development_goal_status_in_progress", bundle: PresentationResources.bundle)
        } icon: {
            Image(systemName: "clock")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.accent.opacity(0.1), in: .capsule)
    }
}

enum HomeGoalPresentation: Identifiable {
    case create
    case detail(String)

    var id: String {
        switch self {
        case .create:
            "create"
        case .detail(let goalID):
            goalID
        }
    }
}
