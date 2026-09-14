//
//  RecordVersionHistoryView.swift
//  Development
//
//  Created by opfic on 9/14/26.
//

import SwiftUI
import Domain
import PresentationShared

struct RecordVersionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var destination: VersionDestination?

    let store: StoreOf<RecordDetailFeature>

    private var sortedVersions: [DevelopmentRecord.Version] {
        store.versions.sorted { $1.number < $0.number }
    }

    private var currentVersion: DevelopmentRecord.Version? {
        store.currentVersion
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                titleSection
                currentVersionCard
                historyCard
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .background(Color.appBackground)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .navigationDestination(item: $destination) { destination in
            RecordVersionDetailView(
                store: store,
                version: destination.version
            )
        }
    }

    private var topBar: some View {
        HStack {
            RecordBackButton(action: dismiss.callAsFunction)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
        .background(Color.appBackground, ignoresSafeAreaEdges: .top)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(RecordPresentation.text("development_record_history_title"))
                .font(.largeTitle.bold())

            if let currentVersion {
                Text(currentVersion.title)
                    .font(.title3)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
            }
        }
    }

    @ViewBuilder
    private var currentVersionCard: some View {
        if let currentVersion {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: "doc.text")
                    .font(.title2)
                    .foregroundStyle(Color.accent)
                    .frame(width: 56, height: 56)
                    .background(Color.accent.opacity(0.12), in: .rect(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(RecordPresentation.text("development_record_current_version"))
                            .font(.headline)

                        RecordVersionBadge(number: currentVersion.number, isCurrent: false)
                    }

                    Text(RecordPresentation.text("development_record_current_version_message"))
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.primaryContainer, in: .rect(cornerRadius: 24))
        }
    }

    private var historyCard: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(sortedVersions.enumerated()), id: \.element.id) { index, version in
                Button {
                    if version.id == store.currentVersionID {
                        dismiss()
                    } else {
                        destination = VersionDestination(version: version)
                    }
                } label: {
                    VersionHistoryRow(
                        version: version,
                        isCurrent: version.id == store.currentVersionID,
                        isLast: index == sortedVersions.count - 1
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(Color.surface, in: .rect(cornerRadius: 28))
    }

    private var footer: some View {
        Label(
            RecordPresentation.text("development_record_history_footer"),
            systemImage: "lock"
        )
        .font(.caption)
        .foregroundStyle(Color.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.appBackground, ignoresSafeAreaEdges: .bottom)
    }
}

private struct VersionHistoryRow: View {
    let version: DevelopmentRecord.Version
    let isCurrent: Bool
    let isLast: Bool

    var body: some View {
        HStack(spacing: 8) {
            HStack(alignment: .top, spacing: 16) {
                timelineIndicator

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        RecordVersionBadge(number: version.number, isCurrent: false)

                        if isCurrent {
                            statusBadge(
                                RecordPresentation.text("development_record_version_current"),
                                foreground: .white,
                                background: .accent
                            )
                        }

                        kindBadge
                    }

                    Text(version.confirmedAt, format: .dateTime.month().day().hour().minute())
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)

                    Text(version.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color.border)
        }
        .contentShape(.rect)
        .background(alignment: .topLeading) {
            if !isLast {
                Rectangle()
                    .fill(Color.accent.opacity(0.45))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .offset(x: 5.5, y: 16)
            }
        }
    }

    private var timelineIndicator: some View {
        Circle()
            .fill(isCurrent ? Color.accent : Color.textTertiary)
            .frame(width: 13, height: 13)
            .overlay {
                Circle()
                    .strokeBorder(isCurrent ? Color.accent : Color.border, lineWidth: 2)
            }
            .padding(.top, 3)
    }

    @ViewBuilder
    private var kindBadge: some View {
        switch version.kind {
        case .initial:
            statusBadge(
                RecordPresentation.text("development_record_version_initial"),
                foreground: .textSecondary,
                background: .surfaceSecondary
            )
        case .correction:
            statusBadge(
                RecordPresentation.text("development_record_version_correction"),
                foreground: .accent,
                background: .primaryContainer
            )
        case .rollback:
            statusBadge(
                RecordPresentation.text("development_record_version_rollback"),
                foreground: .warning,
                background: .warning.opacity(0.12)
            )
        }
    }

    private func statusBadge(
        _ title: String,
        foreground: Color,
        background: Color
    ) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(background, in: .rect(cornerRadius: 8))
    }
}

struct RecordVersionBadge: View {
    let number: Int
    let isCurrent: Bool

    var body: some View {
        Text(RecordPresentation.versionLabel(number))
            .font(.caption.weight(.semibold))
            .foregroundStyle(isCurrent ? Color.white : Color.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                isCurrent ? Color.accent : Color.primaryContainer,
                in: .capsule
            )
    }
}

struct RecordBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.title3.weight(.semibold))
                .frame(width: 28, height: 28)
        }
        .adaptiveButtonStyle(shape: .circle, color: .surface, glassEffect: .enabled)
    }
}

private struct VersionDestination: Identifiable {
    let version: DevelopmentRecord.Version
    var id: String { version.id }
}
