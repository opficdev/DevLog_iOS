//
//  DevelopmentRecordDetailView.swift
//  Development
//
//  Created by opfic on 9/13/26.
//

import SwiftUI
import Domain
import PresentationShared

public struct DevelopmentRecordDetailView: View {
    @State private var store: StoreOf<DevelopmentRecordDetailFeature>

    public init(goalTitle: String, record: DevelopmentRecord) {
        self._store = State(initialValue: Store(
            initialState: DevelopmentRecordDetailFeature.State(
                goalTitle: goalTitle,
                record: record
            )
        ) {
            DevelopmentRecordDetailFeature()
        })
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                goalBadge
                detailContent
            }
            .padding()
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.send(.view(.fetch)) }
        .prominentAlert(store, state: \.alert, action: \.alert)
        .overlay {
            if store.isLoading {
                LoadingView()
            }
        }
    }

    private var goalBadge: some View {
        Text(store.goalTitle)
            .font(.callout)
            .foregroundStyle(Color.accent)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.primaryContainer, in: .capsule)
            .lineLimit(1)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch store.contentState {
        case .draft(let draft):
            recordContent(
                title: draft.title,
                markdownContent: draft.markdownContent,
                version: nil
            )
        case .confirmed(let version):
            recordContent(
                title: version.title,
                markdownContent: version.markdownContent,
                version: version
            )
        case .failed:
            failureContent
        case .idle, .loading:
            Color.clear.frame(height: 1)
        }
    }

    @ViewBuilder
    private func recordContent(
        title: String,
        markdownContent: String,
        version: DevelopmentRecord.Version?
    ) -> some View {
        titleSection(title: title, version: version)
        contentCard(markdownContent: markdownContent)
    }

    private func titleSection(
        title: String,
        version: DevelopmentRecord.Version?
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                Text(statusText(isDraft: version == nil))
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(statusColor(isDraft: version == nil))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(statusBackground(isDraft: version == nil), in: .capsule)

                if let version {
                    Text(DevelopmentRecordPresentation.versionLabel(version.number))
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.primaryContainer, in: .capsule)

                    Text(version.confirmedAt, format: .dateTime.month().day().hour().minute())
                        .font(.callout)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    private func contentCard(markdownContent: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if markdownContent.isEmpty {
                ContentUnavailableView(
                    DevelopmentRecordPresentation.text("development_record_content_empty_title"),
                    systemImage: "doc.text"
                )
            } else {
                MarkdownContentView(content: markdownContent)
                    .frame(minHeight: 420)
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.surface)
        }
    }

    private var failureContent: some View {
        VStack(spacing: 20) {
            ContentUnavailableView(
                DevelopmentRecordPresentation.text("common_error_title"),
                systemImage: "exclamationmark.triangle",
                description: Text(
                    DevelopmentRecordPresentation.text("development_record_detail_error_message")
                )
            )

            Button(DevelopmentRecordPresentation.text("development_record_detail_retry")) {
                store.send(.view(.fetch))
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.surface, in: .rect(cornerRadius: 24))
    }

    private func statusText(isDraft: Bool) -> String {
        isDraft
            ? DevelopmentRecordPresentation.text("development_record_draft")
            : DevelopmentRecordPresentation.text("development_record_confirmed")
    }

    private func statusColor(isDraft: Bool) -> Color {
        isDraft ? .warning : .white
    }

    private func statusBackground(isDraft: Bool) -> Color {
        isDraft ? .warning.opacity(0.12) : .accent
    }
}
