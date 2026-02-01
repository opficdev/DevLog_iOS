//
//  TodoEditorView.swift
//  DevLog
//
//  Created by opfic on 5/31/25.
//

import SwiftUI
import MarkdownUI

struct TodoEditorView: View {
    @StateObject var viewModel: TodoEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState var focusOnContentField: Bool
    var onSubmit: ((Todo) -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        titleField
                        LazyVStack(
                            alignment: .leading,
                            spacing: 0,
                            pinnedViews: [.sectionHeaders]
                        ) {
                            Section {
                                tabView
                            } header: {
                                tabViewSelector
                            }
                        }
                    }
                }
                .onTapGesture {
                    focusOnContentField = true
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolBar }
        }
    }

    private var titleField: some View {
        TextField("", text: Binding(
            get: { viewModel.state.title },
            set: { viewModel.send(.setTitle($0)) }
        ),
                  prompt: Text("제목").foregroundColor(Color.gray)
        )
        .font(.title3)
        .padding(.horizontal)
    }

    private var dueDateSelector: some View {
        HStack {
            if let dueDate = viewModel.state.dueDate {
                HStack {
                    DatePicker(
                        "마감일",
                        selection: Binding(
                            get: { dueDate },
                            set: { viewModel.send(.setDueDate($0)) }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .foregroundStyle(viewModel.state.hasDueDate ? Color.primary : Color.secondary)
                    Divider()
                    Button(action: {
                        viewModel.send(.toggleDueDate)
                    }) {
                        CheckBox(isChecked: viewModel.state.hasDueDate)
                    }
                }
                .padding(.horizontal)
            } else {

            }
        }
    }

    private var tagField: some View {
        HStack {
            Text("태그")
                .foregroundStyle(viewModel.state.tags.isEmpty ? Color.secondary : Color.primary)
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(viewModel.state.tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Button(action: {
                                viewModel.send(.removeTag(tag))
                            }) {
                                Image(systemName: "xmark")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 8)
                        .background(
                            Capsule()
                                .fill(Color(UIColor.systemFill))
                        )
                    }

                    TextField(
                        "",
                        text: Binding(
                            get: { viewModel.state.tagText },
                            set: { viewModel.send(.setTagText($0)) }
                        )
                    )
//                    .focused($focusOnTagField)
                    .onSubmit {
                        viewModel.send(.addTag)
                    }
//                    .onChange(of: focusOnTagField) { focused in
//                        if !focused {
//                            viewModel.send(.addTag)
//                        }
//                    }
                }
            }
            Divider()
            Button(action: {
//                focusOnTagField.toggle()
//                if focusOnTagField {
//                    focusOnContentField = false
//                }
            }) {
//                Image(systemName: "\(focusOnTagField ? "xmark" : "plus").circle.fill")
//                    .font(.title2)
            }
        }
        .padding(.horizontal)
    }

    private var tabViewSelector: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button(action: {
                    viewModel.send(.setTabViewTag(.editor))
                }) {
                    Text("편집")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(
                            viewModel.state.tabViewTag == .editor ? Color.primary : Color.secondary
                        )
                }
                Divider()
                Button(action: {
                    viewModel.send(.setTabViewTag(.preview))
                }) {
                    Text("미리보기")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(
                            viewModel.state.tabViewTag == .preview ? Color.primary : Color.gray
                        )
                }
            }
            .padding(.vertical, 10)
            .background(Color(UIColor.systemBackground))
        }
    }

    private var tabView: some View {
        Group {
            if viewModel.state.tabViewTag == .editor {
                TextField(
                    "",
                    text: Binding(
                        get: { viewModel.state.content },
                        set: { viewModel.send(.setContent($0)) }
                    ),
                    prompt: Text("설명(선택 사항)").font(.callout),
                    axis: .vertical
                )
                .focused($focusOnContentField)
            } else {
                Markdown(viewModel.state.content)
                    .markdownTheme(.basic)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    @ToolbarContentBuilder
    private var toolBar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")}
            .bold()
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: {
                onSubmit?(viewModel.upsertTodo())
                dismiss()
            }) {
                Text("추가")
            }
            .disabled(!viewModel.state.isValidToSave)
        }
    }
}
