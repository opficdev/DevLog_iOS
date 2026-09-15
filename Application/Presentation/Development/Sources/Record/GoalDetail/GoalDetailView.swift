//
//  GoalDetailView.swift
//  Development
//
//  Created by opfic on 9/13/26.
//

import SwiftUI
import Domain
import PresentationShared

public struct GoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store: StoreOf<GoalDetailFeature>
    @State private var editorDestination: EditorDestination?
    @State private var detailDestination: DetailDestination?

    public init(goalId: String) {
        self._store = State(initialValue: Store(
            initialState: GoalDetailFeature.State(goalId: goalId)
        ) {
            GoalDetailFeature()
        })
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 20, pinnedViews: [.sectionHeaders]) {
                Section {
                    timelineCard
                    if store.allowsRecordMutation,
                       let draft = store.items.first(where: \.hasDraft) {
                        continueButton(draft.record)
                    }
                } header: {
                    titleBar
                }
                .padding(.horizontal)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbarVisibility(.hidden, for: .navigationBar)
        .onAppear { store.send(.view(.fetch)) }
        .prominentAlert(store, state: \.alert, action: \.alert)
        .sheet(item: $editorDestination) { destination in
            RecordEditorView(
                goalId: store.goalId,
                goalTitle: store.goalTitle,
                record: destination.record,
                onCompletion: finishEditing
            )
        }
        .navigationDestination(item: $detailDestination) { destination in
            RecordDetailView(
                goalTitle: store.goalTitle,
                record: destination.record,
                allowsMutation: store.allowsRecordMutation,
                onUpdate: refresh
            )
        }
        .overlay {
            if store.isTransitioning {
                LoadingView()
            }
        }
    }

    private var topBar: some View {
        HStack {
            RecordBackButton(action: dismiss.callAsFunction)
                .disabled(store.isTransitioning)
            Spacer()
            if let status = store.goalStatus {
                Image(systemName: "ellipsis")
                    .font(.title3.weight(.semibold))
                    .frame(width: 28, height: 28)
                    .prominentMenu(
                        items: statusMenuItems(status),
                        isEnabled: !store.isLoading && !store.isTransitioning
                    ) { status in
                        store.send(.view(.selectStatus(status)))
                    }
                    .adaptiveButtonStyle(
                        shape: .circle,
                        color: .surface,
                        glassEffect: .enabled
                    )
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
        .background(Color.appBackground, ignoresSafeAreaEdges: .top)
    }

    private var titleBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(RecordPresentation.text("development_goal_title"))
                .font(.largeTitle.bold())

            if !store.goalTitle.isEmpty {
                ScrollView(.horizontal) {
                    Text(store.goalTitle)
                        .font(.headline)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }
                .scrollIndicators(.hidden)
                .contentMargins(.horizontal, 16, for: .scrollContent)
                .padding(.horizontal, -16)
            }

            if let status = store.goalStatus {
                GoalStatusBadge(status: status)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appBackground)
    }

    @ViewBuilder
    private var timelineCard: some View {
        VStack(spacing: 18) {
            if !store.hasLoaded, store.hasLoadFailure {
                ContentUnavailableView {
                    Label(
                        RecordPresentation.text("common_error_title"),
                        systemImage: "exclamationmark.triangle"
                    )
                } description: {
                    Text(RecordPresentation.text("development_record_timeline_error_message"))
                } actions: {
                    Button {
                        store.send(.view(.refresh))
                    } label: {
                        Text(RecordPresentation.text("development_record_timeline_retry"))
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if !store.hasLoaded || store.isLoading, store.items.isEmpty {
                ProgressView()
                    .tint(Color.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else if store.items.isEmpty {
                ContentUnavailableView(
                    RecordPresentation.text("development_record_empty_title"),
                    systemImage: "doc.badge.plus",
                    description: Text(RecordPresentation.text("development_record_empty_message"))
                )
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(store.items.enumerated()), id: \.element.id) { index, item in
                        TimelineRow(
                            item: item,
                            isFirst: index == 0,
                            isLast: index == store.items.count - 1,
                            onSelect: { select(item) }
                        )
                    }
                }
            }

            if store.hasLoaded, store.allowsRecordMutation {
                Button {
                    editorDestination = EditorDestination(record: nil)
                } label: {
                    Label(
                        RecordPresentation.text("development_record_add"),
                        systemImage: "plus"
                    )
                    .font(.callout)
                    .foregroundStyle(Color.accent)
                }
                .adaptiveButtonStyle(color: .primaryContainer)
                .disabled(store.isLoading)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.surface)
        }
    }

    private func continueButton(_ record: DevelopmentRecord) -> some View {
        Button {
            editorDestination = EditorDestination(record: record)
        } label: {
            Text(RecordPresentation.text("development_record_continue"))
                .font(.headline)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .adaptiveButtonStyle(shape: RoundedRectangle(cornerRadius: 16), color: .accent)
    }

    private func select(_ item: RecordTimelineItem) {
        if item.hasDraft, store.allowsRecordMutation {
            editorDestination = EditorDestination(record: item.record)
        } else {
            detailDestination = DetailDestination(record: item.record)
        }
    }

    private func statusMenuItems(
        _ status: DevelopmentGoal.Status
    ) -> [ProminentMenuItem<DevelopmentGoal.Status>] {
        switch status {
        case .inProgress:
            [
                ProminentMenuItem(
                    action: .completed,
                    title: RecordPresentation.text("development_goal_complete"),
                    systemImage: "checkmark.circle"
                ),
                ProminentMenuItem(
                    action: .archived,
                    title: RecordPresentation.text("development_goal_archive"),
                    systemImage: "archivebox"
                )
            ]
        case .completed, .archived:
            [
                ProminentMenuItem(
                    action: .inProgress,
                    title: RecordPresentation.text("development_goal_resume"),
                    systemImage: "arrow.counterclockwise"
                )
            ]
        }
    }

    private func finishEditing() {
        editorDestination = nil
        refresh()
    }

    private func refresh() {
        store.send(.view(.refresh))
    }
}

private struct TimelineRow: View {
    let item: RecordTimelineItem
    let isFirst: Bool
    let isLast: Bool
    let onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(alignment: .top, spacing: 16) {
                timelineIndicator
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                    status
                    if item.hasDraft {
                        RelativeTimeText(
                            date: item.date,
                            bodyFont: .caption,
                            bodyColor: .textTertiary
                        )
                    } else {
                        Text(item.date, format: .dateTime.month().day())
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.border)
                    .padding(.top, 4)
            }
            .contentShape(.rect)
            .frame(minHeight: RecordTimelineLayout.rowHeight, alignment: .top)
            .background(alignment: .topLeading) {
                RecordTimelineConnector(isFirst: isFirst, isLast: isLast)
            }
        }
        .buttonStyle(.plain)
    }

    private var timelineIndicator: some View {
        Circle()
            .fill(item.hasDraft ? Color.warning : .accent)
            .frame(width: RecordTimelineLayout.markerSize, height: RecordTimelineLayout.markerSize)
            .padding(.top, RecordTimelineLayout.markerTopPadding)
    }

    private var status: some View {
        Text(statusText)
            .font(.caption)
            .foregroundStyle(item.hasDraft ? Color.warning : .accent)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                item.hasDraft ? Color.warning.opacity(0.12) : Color.primaryContainer,
                in: .rect(cornerRadius: 8)
            )
    }

    private var statusText: String {
        guard let versionNumber = item.versionNumber else {
            return RecordPresentation.text("development_record_draft_status")
        }
        return String.localizedStringWithFormat(
            RecordPresentation.text("development_record_confirmed_version_format"),
            RecordPresentation.versionLabel(versionNumber)
        )
    }
}

private struct GoalStatusBadge: View {
    let status: DevelopmentGoal.Status

    var body: some View {
        Label(title, systemImage: systemImage)
        .font(.caption.weight(.semibold))
        .foregroundStyle(foreground)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(background, in: .capsule)
    }

    private var title: String {
        switch status {
        case .inProgress:
            RecordPresentation.text("development_goal_status_in_progress")
        case .completed:
            RecordPresentation.text("development_goal_status_completed")
        case .archived:
            RecordPresentation.text("development_goal_status_archived")
        }
    }

    private var systemImage: String {
        switch status {
        case .inProgress:
            "clock"
        case .completed:
            "checkmark.circle.fill"
        case .archived:
            "archivebox.fill"
        }
    }

    private var foreground: Color {
        switch status {
        case .inProgress:
            .accent
        case .completed:
            .white
        case .archived:
            .textSecondary
        }
    }

    private var background: Color {
        switch status {
        case .inProgress:
            .primaryContainer
        case .completed:
            .accent
        case .archived:
            .surfaceSecondary
        }
    }
}

private struct EditorDestination: Identifiable {
    let id = UUID()
    let record: DevelopmentRecord?
}

private struct DetailDestination: Identifiable {
    let record: DevelopmentRecord
    var id: String { record.id }
}
