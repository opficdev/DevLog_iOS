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
                titleSection
                contentCard
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

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                Text(statusText)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(statusBackground, in: .capsule)

                if let version = store.currentVersion {
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

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(DevelopmentRecordPresentation.text("development_record_result_title"))
                .font(.title2)

            if content.isEmpty {
                ContentUnavailableView(
                    DevelopmentRecordPresentation.text("development_record_content_empty_title"),
                    systemImage: "doc.text"
                )
            } else {
                MarkdownContentView(content: content)
                    .frame(minHeight: 420)
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.surface)
        }
    }

    private var title: String {
        store.currentVersion?.title ?? store.record.draft?.title ?? ""
    }

    private var content: String {
        store.currentVersion?.markdownContent ?? store.record.draft?.markdownContent ?? ""
    }

    private var statusText: String {
        store.currentVersion == nil
            ? DevelopmentRecordPresentation.text("development_record_draft")
            : DevelopmentRecordPresentation.text("development_record_confirmed")
    }

    private var statusColor: Color {
        store.currentVersion == nil ? .warning : .white
    }

    private var statusBackground: Color {
        store.currentVersion == nil ? .warning.opacity(0.12) : .accent
    }
}
