//
//  TodoEditorView.swift
//  DevLog
//
//  Created by opfic on 5/31/25.
//

import SwiftUI
import MarkdownUI

struct TodoEditorView: View {
    @ObservedObject var viewModel: TodoEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState var focusOnTagField: Bool
    var onSubmit: (() -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    TextField("", text: Binding(
                        get: { viewModel.state.title },
                        set: { viewModel.send(.setTitle($0)) }
                    ),
                        prompt: Text("제목").foregroundColor(Color.gray)
                    )
                    .font(.title3)
                    .padding(.horizontal)
                    Divider()
                    if let dueDate = viewModel.state.dueDate {
                        HStack {
                            DatePicker("마감일",
                                       selection: Binding(
                                        get: { dueDate },
                                        set: { viewModel.send(.setDueDate($0)) }
                                       ),
                                       displayedComponents: .date)
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
                    }
                    Divider()
                    HStack {
                        Text("태그")
                            .foregroundStyle(viewModel.state.tags.isEmpty ? Color.secondary : Color.primary)
                        Divider()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(viewModel.state.tags, id: \.self) { tag in
                                    HStack {
                                        Text(tag)
                                        Button(action: {
                                            viewModel.send(.removeTag(tag))
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.caption)
                                                .foregroundStyle(Color.gray)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color(UIColor.systemFill))
                                    )
                                }

                                TextField("",
                                          text: Binding(
                                            get: { viewModel.state.tagText },
                                            set: { viewModel.send(.setTagText($0)) }
                                          ))
                                    .focused($focusOnTagField)
                                    .onSubmit {
                                        viewModel.send(.addTag)
                                    }
                                    .onChange(of: focusOnTagField) { focused in
                                        if !focused {
                                            viewModel.send(.addTag)
                                        }
                                    }
                            }
                        }
                        Divider()
                        Button(action: {
                            focusOnTagField.toggle()
                        }) {
                            Image(systemName: "\(focusOnTagField ? "xmark" : "plus").circle.fill")
                                .foregroundStyle(Color.gray)
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                }
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        Group {
                            if viewModel.state.tabViewTag == .editor {
                                TextField(
                                    "",
                                    text: Binding(
                                        get: { viewModel.state.content },
                                        set: { viewModel.send(.setContent($0)) }
                                    ),
                                    prompt: Text("내용을 입력하세요"),
                                    axis: .vertical
                                )
                            } else {
                                Markdown(viewModel.state.content)
                                    .markdownTheme(.basic)
                            }
                        }
                        .padding(.horizontal)
                    } header: {
                        VStack(spacing: 0) {
                            Divider()
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
                            Divider()
                        }
                    }
                }
            }
            .navigationTitle(viewModel.state.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")}
                    .bold()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        onSubmit?()
                        dismiss()
                    }) {
                        Text("추가")
                    }
                    .disabled(!viewModel.state.isValidToSave)
                }
            }
        }
    }
}
