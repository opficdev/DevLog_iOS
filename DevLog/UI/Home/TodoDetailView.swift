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
                            .font(.title3)
                            .padding(.horizontal)
                        if let date = todo.dueDate {
                            Divider()
                            HStack {
                                Text("마감일")
                                Spacer()
                                Text(date.formatted(date: .long, time: .omitted))
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.2))
                                    )
                            }
                            .padding(.horizontal)
                        }
                        Divider()
                        HStack {
                            Text("태그")
                            Divider()
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(todo.tags, id: \.self) { tag in
                                        Text(tag)
                                            .padding(.horizontal, 8)
                                            .background(
                                                Capsule()
                                                    .fill(Color(UIColor.systemFill))
                                            )
                                    }
                                }
                            }
                            .scrollIndicators(.never)
                        }
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.send(.setShowEditor(true))
                } label: {
                    Text("수정")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}
