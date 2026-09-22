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
    @State private var store: StoreOf<RecordEditorFeature>
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
        baseVersion: DevelopmentRecord.Version? = nil,
        onCompletion: @escaping () -> Void = { }
    ) {
        self._store = State(initialValue: Store(
            initialState: RecordEditorFeature.State(
                goalId: goalId,
                goalTitle: goalTitle,
                record: record,
                baseVersion: baseVersion
            )
        ) {
            RecordEditorFeature()
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
        .interactiveDismissDisabled(store.isLoading)
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                if #available(iOS 26.0, *) {
                    Image(systemName: "xmark")
                        .frame(width: iconSize, height: iconSize)
                        .font(.title)
                } else {
                    Text(RecordPresentation.text("common_close"))
                }
            }
            .topBarButtonStyle()
            .disabled(store.isLoading)
            Spacer()
            Text(RecordPresentation.text(
                store.isCorrection
                    ? "development_record_editor_correction_title"
                    : "development_record_editor_title"
            ))
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
                        .font(.title)
                } else {
                    Text(RecordPresentation.text("development_record_save"))
                        .foregroundStyle(Color.accent)
                }
            }
            .topBarButtonStyle(color: Color.surface)
            .disabled(!store.isReadyToSave)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.appBackground, ignoresSafeAreaEdges: .top)
    }

    private var versionCard: some View {
        FieldCard(title: RecordPresentation.text("development_record_version")) {
            Text(RecordPresentation.versionLabel(store.versionNumber))
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.surfaceSecondary, in: .rect(cornerRadius: 16))
        }
    }

    private var titleCard: some View {
        FieldCard(title: RecordPresentation.text("development_record_title")) {
            TextField(
                RecordPresentation.text("development_record_title_placeholder"),
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

            switch store.selectedTab {
            case .write:
                TextEditorContentLayout(minimumHeight: 340 - 24) {
                    Text(RecordPresentation.text("development_record_markdown_hint"))
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                    UIKitTextEditor()
                        .composable(
                            update: { textEditor in
                                textEditor.updateInput(
                                    text: $store.markdownContent,
                                    isFocused: focusedField == .content,
                                    onFocusChange: { isFocused in
                                        if isFocused {
                                            focusedField = .content
                                        } else if focusedField == .content {
                                            focusedField = nil
                                        }
                                    },
                                    isEnabled: !store.isLoading
                                )
                            },
                            sizeThatFits: { UIKitTextEditor.fittingSize(proposal: $0, textEditor: $1) }
                        )
                        .focused($focusedField, equals: .content)
                }
                .padding(12)
                .frame(minHeight: 340, alignment: .topLeading)
                .background(Color.surfaceSecondary, in: .rect(cornerRadius: 16))
                .contentShape(.rect)
                .onTapGesture { focusedField = .content }
            case .preview:
                Group {
                    if store.markdownContent.isEmpty {
                        ContentUnavailableView(
                            RecordPresentation.text("development_record_preview_empty_title"),
                            systemImage: "doc.text.magnifyingglass",
                            description: Text(
                                RecordPresentation.text("development_record_preview_empty_message")
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
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.surface)
        }
        .disabled(store.isLoading)
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
                        Text(RecordPresentation.text(
                            store.isCorrection
                                ? "development_record_confirm_correction"
                                : "development_record_confirm"
                        ))
                    }
                }
                .font(.headline)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .adaptiveButtonStyle(shape: RoundedRectangle(cornerRadius: 16), color: .accent)
            .disabled(!store.canConfirmVersion)

            Text(String.localizedStringWithFormat(
                RecordPresentation.text("development_record_confirm_hint_format"),
                RecordPresentation.versionLabel(store.versionNumber)
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
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.surface)
                }
        }
    }
}

private struct ModePicker: View {
    @Bindable var store: StoreOf<RecordEditorFeature>
    @FocusState var focusedField: Field?

    var body: some View {
        HStack(spacing: 0) {
            modeButton(
                RecordPresentation.text("development_record_write"),
                tab: .write
            )
            modeButton(
                RecordPresentation.text("development_record_preview"),
                tab: .preview
            )
        }
        .padding(2)
        .background(Color.border, in: RoundedRectangle(cornerRadius: 16))
    }

    private func modeButton(
        _ title: String,
        tab: RecordEditorFeature.EditorTab
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
