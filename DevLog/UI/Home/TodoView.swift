//
//  TodoView.swift
//  DevLog
//
//  Created by opfic on 5/30/25.
//

import SwiftUI

struct TodoView: View {
    @StateObject var viewModel: TodoViewModel

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.state.todos.isEmpty {
                    VStack {
                        Spacer()
                        Text("작성된 내용이 없습니다.")
                            .foregroundStyle(Color.gray)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    List(viewModel.state.todos) { todo in
                        NavigationLink(value: todo) {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    if todo.isPinned {
                                        Image(systemName: "star.fill")
                                            .font(.headline)
                                            .foregroundStyle(Color.orange)
                                    }
                                    Text(todo.title)
                                        .font(.headline)
                                        .lineLimit(1)
                                }
                                Text(todo.content)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.gray)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 5)
                        }
                        .swipeActions(edge: .leading) {
                            Button(action: {
                                viewModel.send(.didTapTogglePinned(todo))
                            }) {
                                Image(systemName: "star\(todo.isPinned ? ".slash" : ".fill")")
                            }
                            .tint(Color.orange)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive, action: {
                                viewModel.send(.didSwipeTodo(todo))
                            }) {
                                Image(systemName: "trash")
                            }
                           
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        viewModel.send(.refresh)
                    }
                    .navigationDestination(for: Todo.self) { todo in
                        TodoDetailView(
                            todo: todo,
                            onSubmit: { viewModel.send(.upsertTodo($0)) }
                        )
                    }
                }
            }
            .navigationTitle(viewModel.state.kind.localizedName)
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.state.showEditor },
                set: { _, _ in viewModel.send(.openEditor) })
            ) {
                let title = "새 \(viewModel.state.kind.localizedName)"
                TodoEditorView(
                    viewModel: TodoEditorViewModel(title: title),
                    onSubmit: { viewModel.send(.upsertTodo($0)) }
                )
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu(content: {
                        Section {
                            Button(action: {
                                viewModel.send(.didTapFilterOption(.create))
                            }) {
                                if viewModel.state.filterOption == .create {
                                    Image(systemName: "checkmark")
                                        .tint(Color.blue)
                                }
                                Text("생성")
                            }
                            Button(action: {
                                viewModel.send(.didTapFilterOption(.update))
                            }) {
                                if viewModel.state.filterOption == .update {
                                    Image(systemName: "checkmark")
                                        .tint(Color.blue)
                                }
                                Text("수정")
                            }
                        } header: {
                            Text("정렬 옵션")
                        }
                        
                        Section {
                            Button(action: {
                                viewModel.send(.didTapFilterOption(.day))
                            }) {
                                if viewModel.state.filterOption == .day {
                                    Image(systemName: "checkmark")
                                        .tint(Color.blue)
                                }
                                Text("어제")
                            }
                            Button(action: {
                                viewModel.send(.didTapFilterOption(.week))
                            }) {
                                if viewModel.state.filterOption == .week {
                                    Image(systemName: "checkmark")
                                        .tint(Color.blue)
                                }
                                Text("지난주")
                            }
                            Button(action: {
                                viewModel.send(.didTapFilterOption(.month))
                            }) {
                                if viewModel.state.filterOption == .month {
                                    Image(systemName: "checkmark")
                                        .tint(Color.blue)
                                }
                                Text("지난달")
                            }
                            Button(action: {
                                viewModel.send(.didTapFilterOption(.year))
                            }) {
                                if viewModel.state.filterOption == .year {
                                    Image(systemName: "checkmark")
                                        .tint(Color.blue)
                                }
                                Text("작년")
                            }
                        } header: {
                            Text("필터 옵션")
                        }
                    }, label: {
                        Image(systemName: "ellipsis")
                    })
                    Button(action: {
                        viewModel.send(.openEditor)
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .searchable(
                text: Binding(
                    get: { viewModel.state.searchText },
                    set: { viewModel.send(.setSearchText($0)) }
                ),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "\(viewModel.state.kind.localizedName) 검색"
            )
            .searchScopes(Binding(
                get: { viewModel.state.scope },
                set: { viewModel.send(.setScope($0)) }
            )) {
                ForEach(TodoScope.allCases, id: \.self) { scope in
                    Text(scope.localizedName).tag(scope)
                }
            }
            .task {
                viewModel.send(.onAppear)
            }
            .overlay {
                if viewModel.state.isLoading {
                    LoadingView()
                }
            }
        }
    }
}
