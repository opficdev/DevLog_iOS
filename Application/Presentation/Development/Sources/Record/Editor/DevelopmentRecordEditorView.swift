//
//  DevelopmentRecordEditorView.swift
//  Development
//
//  Created by opfic on 9/13/26.
//

import SwiftUI
import Domain
import PresentationShared

public struct DevelopmentRecordEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store: StoreOf<DevelopmentRecordEditorFeature>
    @FocusState private var focusedField: Field?
    private let onCompletion: () -> Void

    public init(
        goalId: String,
        goalTitle: String,
        record: DevelopmentRecord? = nil,
        onCompletion: @escaping () -> Void = { }
    ) {
        self._store = State(initialValue: Store(
            initialState: DevelopmentRecordEditorFeature.State(
                goalId: goalId,
                goalTitle: goalTitle,
                record: record
            )
        ) {
            DevelopmentRecordEditorFeature()
        })
        self.onCompletion = onCompletion
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    goalBadge
                    versionCard
                    titleCard
                    contentCard
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .safeAreaInset(edge: .top, spacing: 0) { topBar }
            .safeAreaInset(edge: .bottom, spacing: 0) { confirmBar }
            .background(Color.appBackground.ignoresSafeArea())
            .toolbarVisibility(.hidden, for: .navigationBar)
            .prominentAlert(store, state: \.alert, action: \.alert)
            .onChange(of: store.result) { _, result in
                guard result != nil else { return }
                onCompletion()
                dismiss()
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button(DevelopmentRecordPresentation.text("common_close")) {
                dismiss()
            }
            .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(DevelopmentRecordPresentation.text("development_record_editor_title"))
                .font(.headline)
            Spacer()
            Button(DevelopmentRecordPresentation.text("development_record_save")) {
                focusedField = nil
                store.send(.view(.save))
            }
            .fontWeight(.semibold)
            .foregroundStyle(Color.accent)
            .disabled(!store.isReadyToSave)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.appBackground, ignoresSafeAreaEdges: .top)
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

    private var versionCard: some View {
        FieldCard(title: DevelopmentRecordPresentation.text("development_record_version")) {
            Text(DevelopmentRecordPresentation.versionLabel(store.versionNumber))
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.surfaceSecondary, in: .rect(cornerRadius: 16))
        }
    }

    private var titleCard: some View {
        FieldCard(title: DevelopmentRecordPresentation.text("development_record_title")) {
            TextField(
                DevelopmentRecordPresentation.text("development_record_title_placeholder"),
                text: $store.title
            )
            .focused($focusedField, equals: .title)
            .padding()
            .background(Color.surfaceSecondary, in: .rect(cornerRadius: 16))
        }
        .disabled(store.isLoading)
    }

    private var contentCard: some View {
        VStack(spacing: 16) {
            Picker(
                DevelopmentRecordPresentation.text("development_record_editor_mode"),
                selection: $store.selectedTab
            ) {
                Text(DevelopmentRecordPresentation.text("development_record_write"))
                    .tag(DevelopmentRecordEditorFeature.EditorTab.write)
                Text(DevelopmentRecordPresentation.text("development_record_preview"))
                    .tag(DevelopmentRecordEditorFeature.EditorTab.preview)
            }
            .pickerStyle(.segmented)

            editorContent

            Text(DevelopmentRecordPresentation.text("development_record_markdown_hint"))
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.surface)
        }
        .disabled(store.isLoading)
    }

    @ViewBuilder
    private var editorContent: some View {
        switch store.selectedTab {
        case .write:
            TextEditor(text: $store.markdownContent)
                .focused($focusedField, equals: .content)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(12)
                .frame(minHeight: 340, alignment: .topLeading)
                .background(Color.surfaceSecondary, in: .rect(cornerRadius: 16))
        case .preview:
            Group {
                if store.markdownContent.isEmpty {
                    ContentUnavailableView(
                        DevelopmentRecordPresentation.text("development_record_preview_empty_title"),
                        systemImage: "doc.text.magnifyingglass",
                        description: Text(
                            DevelopmentRecordPresentation.text("development_record_preview_empty_message")
                        )
                    )
                } else {
                    MarkdownContentView(content: store.markdownContent)
                        .padding(.vertical, 16)
                }
            }
            .frame(minHeight: 340)
            .background(Color.surfaceSecondary, in: .rect(cornerRadius: 16))
        }
    }

    private var confirmBar: some View {
        VStack(spacing: 8) {
            Button {
                focusedField = nil
                store.send(.view(.confirm))
            } label: {
                Group {
                    if store.isLoading {
                        ProgressView()
                            .tint(Color.white)
                    } else {
                        Text(DevelopmentRecordPresentation.text("development_record_confirm"))
                    }
                }
                .font(.headline)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .adaptiveButtonStyle(shape: RoundedRectangle(cornerRadius: 16), color: .accent)
            .disabled(!store.canConfirmInitialVersion)

            Text(String.localizedStringWithFormat(
                DevelopmentRecordPresentation.text("development_record_confirm_hint_format"),
                DevelopmentRecordPresentation.versionLabel(store.versionNumber)
            ))
            .font(.caption)
            .foregroundStyle(Color.textTertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.surface, ignoresSafeAreaEdges: .bottom)
    }
}

private struct FieldCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
            content
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.surface)
        }
    }
}

private enum Field: Hashable {
    case title
    case content
}
