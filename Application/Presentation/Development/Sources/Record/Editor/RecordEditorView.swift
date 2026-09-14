//
//  RecordEditorView.swift
//  Development
//
//  Created by opfic on 9/13/26.
//

import SwiftUI
import Domain
import PresentationShared

public struct RecordEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store: StoreOf<DevelopmentRecordEditorFeature>
    @FocusState private var focusedField: Field?
    @ScaledMetric(relativeTo: .title) private var iconSize = UIFont.preferredFont(
        forTextStyle: .title2,
        compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
    ).lineHeight
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
                LazyVStack(alignment: .leading, spacing: 20) {
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
            Button {
                dismiss()
            } label: {
                if #available(iOS 26.0, *) {
                    Image(systemName: "xmark")
                        .frame(width: iconSize, height: iconSize)
                } else {
                    Text(DevelopmentRecordPresentation.text("common_close"))
                }
            }
            .font(.title)
            .topBarButtonStyle()
            Spacer()
            Text(DevelopmentRecordPresentation.text("development_record_editor_title"))
                .font(.headline)
            Spacer()
            Button {
                focusedField = nil
                store.send(.view(.save))
            } label: {
                if #available(iOS 26.0, *) {
                    Image(systemName: "checkmark")
                        .frame(width: iconSize, height: iconSize)
                        .foregroundStyle(Color.primary)
                } else {
                    Text(DevelopmentRecordPresentation.text("development_record_save"))
                        .foregroundStyle(Color.accent)
                }
            }
            .font(.title)
            .topBarButtonStyle(color: Color.surface)
            .disabled(!store.isReadyToSave)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.appBackground, ignoresSafeAreaEdges: .top)
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
            ModePicker(store: store, focusedField: _focusedField)

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

private extension View {
    @ViewBuilder
    func topBarButtonStyle(color: Color = .clear) -> some View {
        if #available(iOS 26.0, *) {
            adaptiveButtonStyle(shape: .circle, color: color, glassEffect: .enabled)
        } else {
            adaptiveButtonStyle(color: color, glassEffect: .enabled)
        }
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

private struct ModePicker: View {
    @Bindable var store: StoreOf<DevelopmentRecordEditorFeature>
    @FocusState var focusedField: Field?

    var body: some View {
        HStack(spacing: 0) {
            modeButton(
                DevelopmentRecordPresentation.text("development_record_write"),
                tab: .write
            )
            modeButton(
                DevelopmentRecordPresentation.text("development_record_preview"),
                tab: .preview
            )
        }
        .padding(2)
        .background(Color.border, in: RoundedRectangle(cornerRadius: 16))
    }

    private func modeButton(
        _ title: String,
        tab: DevelopmentRecordEditorFeature.EditorTab
    ) -> some View {
        let isSelected = store.selectedTab == tab

        return Button {
            if tab == .write {
                store.send(.binding(.set(\.selectedTab, .write)))
                focusedField = .content
            } else {
                focusedField = nil
                DispatchQueue.main.async {
                    store.send(.binding(.set(\.selectedTab, .preview)))
                }
            }
        } label: {
            Text(title)
                .font(.body)
                .foregroundStyle(isSelected ? Color.accent : Color.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.surface)
                            .shadow(color: Color.textSecondary.opacity(0.08), radius: 2, y: 2)
                    }
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private enum Field: Hashable {
    case title
    case content
}
