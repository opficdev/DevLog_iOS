//
//  DevelopmentRecordTimelineView.swift
//  Development
//
//  Created by opfic on 9/13/26.
//

import SwiftUI
import Domain
import PresentationShared

public struct DevelopmentRecordTimelineView: View {
    @State private var store: StoreOf<DevelopmentRecordTimelineFeature>
    @State private var editorDestination: EditorDestination?
    @State private var detailDestination: DetailDestination?

    public init(goalId: String) {
        self._store = State(initialValue: Store(
            initialState: DevelopmentRecordTimelineFeature.State(goalId: goalId)
        ) {
            DevelopmentRecordTimelineFeature()
        })
    }

    public var body: some View {
        VStack(spacing: 20) {
            titleBar
            timelineCard
            if let draft = store.items.first(where: \.isDraft) {
                continueButton(draft.record)
            }
        }
        .onAppear { store.send(.view(.fetch)) }
        .prominentAlert(store, state: \.alert, action: \.alert)
        .sheet(item: $editorDestination) { destination in
            DevelopmentRecordEditorView(
                goalId: store.goalId,
                goalTitle: store.goalTitle,
                record: destination.record,
                onCompletion: finishEditing
            )
        }
        .navigationDestination(item: $detailDestination) { destination in
            DevelopmentRecordDetailView(
                goalTitle: store.goalTitle,
                record: destination.record
            )
        }
    }

    private var titleBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(DevelopmentRecordPresentation.text("development_goal_title"))
                .font(.largeTitle.bold())

            if !store.goalTitle.isEmpty {
                ScrollView(.horizontal) {
                    Text(store.goalTitle)
                        .font(.headline)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Spacer()
                Button {
                    editorDestination = EditorDestination(record: nil)
                } label: {
                    Label(
                        DevelopmentRecordPresentation.text("development_record_add"),
                        systemImage: "plus"
                    )
                    .font(.callout)
                    .foregroundStyle(Color.accent)
                }
                .adaptiveButtonStyle(color: .primaryContainer)
                .disabled(store.isLoading)
            }

            timelineContent
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.surface)
        }
    }

    @ViewBuilder
    private var timelineContent: some View {
        if store.isLoading, store.items.isEmpty {
            ProgressView()
                .tint(Color.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
        } else if store.items.isEmpty {
            ContentUnavailableView(
                DevelopmentRecordPresentation.text("development_record_empty_title"),
                systemImage: "doc.badge.plus",
                description: Text(DevelopmentRecordPresentation.text("development_record_empty_message"))
            )
        } else {
            LazyVStack(spacing: 0) {
                ForEach(Array(store.items.enumerated()), id: \.element.id) { index, item in
                    TimelineRow(
                        item: item,
                        isLast: index == store.items.count - 1,
                        onSelect: { select(item) }
                    )
                }
            }
        }
    }

    private func continueButton(_ record: DevelopmentRecord) -> some View {
        Button {
            editorDestination = EditorDestination(record: record)
        } label: {
            Text(DevelopmentRecordPresentation.text("development_record_continue"))
                .font(.headline)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .adaptiveButtonStyle(shape: RoundedRectangle(cornerRadius: 16), color: .accent)
    }

    private func select(_ item: DevelopmentRecordTimelineItem) {
        if item.isDraft {
            editorDestination = EditorDestination(record: item.record)
        } else {
            detailDestination = DetailDestination(record: item.record)
        }
    }

    private func finishEditing() {
        editorDestination = nil
        store.send(.view(.refresh))
    }
}

private struct TimelineRow: View {
    let item: DevelopmentRecordTimelineItem
    let isLast: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 14) {
                timelineIndicator
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                    status
                    if item.isDraft {
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
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var timelineIndicator: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(item.isDraft ? Color.surface : Color.accent)
                .frame(width: 13, height: 13)
                .overlay {
                    Circle()
                        .strokeBorder(item.isDraft ? Color.warning : Color.accent, lineWidth: 2)
                }
            if !isLast {
                Rectangle()
                    .fill(Color.accent.opacity(0.45))
                    .frame(width: 2, height: 72)
            }
        }
        .padding(.top, 5)
    }

    private var status: some View {
        Text(statusText)
            .font(.caption)
            .foregroundStyle(item.isDraft ? Color.warning : .accent)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                item.isDraft ? Color.warning.opacity(0.12) : Color.primaryContainer,
                in: .rect(cornerRadius: 8)
            )
    }

    private var statusText: String {
        guard let versionNumber = item.versionNumber else {
            return DevelopmentRecordPresentation.text("development_record_draft_status")
        }
        return String.localizedStringWithFormat(
            DevelopmentRecordPresentation.text("development_record_confirmed_version_format"),
            DevelopmentRecordPresentation.versionLabel(versionNumber)
        )
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
