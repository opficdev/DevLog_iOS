//
//  RecordDetailView.swift
//  Development
//
//  Created by opfic on 9/13/26.
//

import SwiftUI
import Domain
import PresentationShared

public struct RecordDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store: StoreOf<RecordDetailFeature>
    @State private var isEditorPresented = false
    @State private var isHistoryPresented = false

    public init(goalTitle: String, record: DevelopmentRecord) {
        self._store = State(initialValue: Store(
            initialState: RecordDetailFeature.State(
                goalTitle: goalTitle,
                record: record
            )
        ) {
            RecordDetailFeature()
        })
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                switch store.contentState {
                case .draft(let draft):
                    recordContent(
                        title: draft.title,
                        markdownContent: draft.markdownContent,
                        version: nil
                    )
                case .loaded:
                    if let version = store.currentVersion {
                        recordContent(
                            title: version.title,
                            markdownContent: version.markdownContent,
                            version: version
                        )
                        actionSection
                    }
                case .failed:
                    failureContent
                case .idle, .loading:
                    Color.clear.frame(height: 1)
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbarVisibility(.hidden, for: .navigationBar)
        .onAppear { store.send(.view(.fetch)) }
        .prominentAlert(store, state: \.alert, action: \.alert)
        .sheet(isPresented: $isEditorPresented) {
            RecordEditorView(
                goalId: store.record.goalId,
                goalTitle: store.goalTitle,
                record: store.record,
                baseVersion: store.currentVersion,
                onCompletion: finishEditing
            )
        }
        .navigationDestination(isPresented: $isHistoryPresented) {
            RecordVersionHistoryView(
                versions: store.versions,
                currentVersionID: store.currentVersionID,
                hasDraft: store.record.draft != nil,
                isRestoring: store.isRestoring,
                restoredSourceVersionID: store.restoredSourceVersionID,
                onRestore: { store.send(.view(.restore($0))) }
            )
        }
        .overlay {
            if store.isLoading || store.isRestoring {
                LoadingView()
            }
        }
    }

    private var topBar: some View {
        HStack {
            RecordBackButton(action: dismiss.callAsFunction)
                .disabled(store.isRestoring)
            Spacer()
        }
        .padding(.horizontal)
        .background(Color.appBackground, ignoresSafeAreaEdges: .top)
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
            ScrollView(.horizontal) {
                Text(title)
                    .font(.title.bold())
                    .lineLimit(1)
            }
            .scrollIndicators(.hidden)

            HStack(spacing: 10) {
                Text(
                    version == nil
                        ? RecordPresentation.text("development_record_draft")
                        : RecordPresentation.text("development_record_confirmed")
                )
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(version == nil ? Color.warning : Color.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        version == nil ? Color.warning.opacity(0.12) : Color.accent,
                        in: .capsule
                    )

                if let version {
                    Text(RecordPresentation.versionLabel(version.number))
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
                    RecordPresentation.text("development_record_content_empty_title"),
                    systemImage: "doc.text"
                )
            } else {
                MarkdownContentView(content: markdownContent)
                    .frame(minHeight: 420)
            }
        }
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.surface)
        }
    }

    private var failureContent: some View {
        VStack(spacing: 20) {
            ContentUnavailableView(
                RecordPresentation.text("common_error_title"),
                systemImage: "exclamationmark.triangle",
                description: Text(
                    RecordPresentation.text("development_record_detail_error_message")
                )
            )

            Button(RecordPresentation.text("development_record_detail_retry")) {
                store.send(.view(.fetch))
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.surface, in: .rect(cornerRadius: 24))
    }

    private var actionSection: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                correctionButton
                historyButton
            }

            VStack(spacing: 12) {
                correctionButton
                historyButton
            }
        }
    }

    private var correctionButton: some View {
        Button {
            isEditorPresented = true
        } label: {
            Label(
                RecordPresentation.text("development_record_correct"),
                systemImage: "pencil"
            )
            .font(.headline)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .adaptiveButtonStyle(shape: RoundedRectangle(cornerRadius: 16), color: .accent)
    }

    private var historyButton: some View {
        Button {
            isHistoryPresented = true
        } label: {
            Label(
                RecordPresentation.text("development_record_history_title"),
                systemImage: "clock.arrow.circlepath"
            )
            .font(.headline)
            .foregroundStyle(Color.onPrimaryContainer)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .adaptiveButtonStyle(
            shape: RoundedRectangle(cornerRadius: 16),
            color: .primaryContainer
        )
    }

    private func finishEditing() {
        isEditorPresented = false
        store.send(.view(.fetch))
    }
}
