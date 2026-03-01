//
//  TodoDetailView.swift
//  DevLog
//
//  Created by opfic on 6/12/25.
//

import SwiftUI
import MarkdownUI

struct TodoDetailView: View {
    @StateObject var viewModel: TodoDetailViewModel

    var body: some View {
        ZStack {
            Color(.secondarySystemBackground).ignoresSafeArea()
            if let todo = viewModel.state.todo {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        Text(todo.title)
                            .font(.title3.bold())
                            .padding(.horizontal)
                        Divider()
                        Markdown(todo.content)
                            .padding(.horizontal)
                    }
                }
            } else if viewModel.state.isLoading {
                LoadingView()
            }
        }
        .onAppear { viewModel.send(.onAppear) }
        .sheet(isPresented: Binding(
            get: { viewModel.state.showInfo },
            set: { viewModel.send(.setShowInfo($0)) }
        )) {
            sheetContent
        }
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.state.showEditor },
            set: { viewModel.send(.setShowEditor($0)) }
        )) {
            if let todo = viewModel.state.todo {
                TodoEditorView(
                    viewModel: TodoEditorViewModel(todo: todo),
                    onSubmit: { viewModel.send(.upsertTodo($0)) }
                )
            }
        }
        .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.send(.setShowInfo(true))
            } label: {
                Image(systemName: "info.circle")
            }
        }
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.send(.setShowEditor(true))
            } label: {
                Text("수정")
            }
        }
    }

    private var sheetContent: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 32) {
                    VStack {
                        HStack {
                            Text("마감일")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text(
                                viewModel.state.todo?.dueDate?
                                    .formatted(date: .abbreviated, time: .omitted)
                                    ?? "마감일 없음"
                            )
                            .foregroundStyle(
                                viewModel.state.todo?.dueDate == nil ? .secondary : .primary
                            )
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.tertiarySystemFill))
                        )
                        Divider()
                    }
                    VStack {
                        HStack {
                            Text("태그")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        Divider()
                        if let tags = viewModel.state.todo?.tags, !tags.isEmpty {
                            TagLayout {
                                ForEach(tags, id: \.self) { tag in
                                    Tag(tag, isEditing: false)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .toolbar {
                ToolbarLeadingButton {
                    viewModel.send(.setShowInfo(false))
                }
            }
        }
    }
}
