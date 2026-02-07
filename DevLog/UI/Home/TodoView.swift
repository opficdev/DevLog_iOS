//
//  TodoView.swift
//  DevLog
//
//  Created by opfic on 5/30/25.
//

import SwiftUI

struct TodoView: View {
    @StateObject var viewModel: TodoViewModel
    @EnvironmentObject var router: NavigationRouter

    var body: some View {
        ZStack {
            if viewModel.state.isLoading {
                LoadingView()
            } else {
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
                        Button {
                            router.push(Path.detail(todo))
                        } label: {
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
                                viewModel.send(.tapTogglePinned(todo))
                            }) {
                                Image(systemName: "star\(todo.isPinned ? ".slash" : ".fill")")
                            }
                            .tint(Color.orange)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive, action: {
                                viewModel.send(.swipeTodo(todo))
                            }) {
                                Image(systemName: "trash")
                            }

                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        viewModel.send(.refresh)
                    }
                    .navigationDestination(for: Path.self) { path in
                        switch path {
                        case .detail(let todo):
                            TodoDetailView(
                                todo: todo,
                                onSubmit: { viewModel.send(.upsertTodo($0)) }
                            )
                        }
                    }
                }
            }
        }
        .alert("불러오기 실패", isPresented: Binding(
            get: { viewModel.state.showAlert },
            set: { _, _ in }
        )) {
            Button(role: .cancel, action: {
                viewModel.send(.closeAlert)
            }) {
                Text("확인")
            }
        } message: {
            Text(viewModel.state.alertMessage)
        }
        .navigationTitle(viewModel.state.kind.localizedName)
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.state.showEditor },
            set: { _, _ in viewModel.send(.closeEditor) })
        ) {
            TodoEditorView(
                viewModel: TodoEditorViewModel(kind: viewModel.state.kind),
                onSubmit: { viewModel.send(.upsertTodo($0)) }
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu(content: {
                    Section {
                        Button(action: {
                            viewModel.send(.tapFilterOption(.create))
                        }) {
                            if viewModel.state.filterOption == .create {
                                Image(systemName: "checkmark")
                                    .tint(Color.blue)
                            }
                            Text("생성")
                        }
                        Button(action: {
                            viewModel.send(.tapFilterOption(.update))
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
                            viewModel.send(.tapFilterOption(.day))
                        }) {
                            if viewModel.state.filterOption == .day {
                                Image(systemName: "checkmark")
                                    .tint(Color.blue)
                            }
                            Text("어제")
                        }
                        Button(action: {
                            viewModel.send(.tapFilterOption(.week))
                        }) {
                            if viewModel.state.filterOption == .week {
                                Image(systemName: "checkmark")
                                    .tint(Color.blue)
                            }
                            Text("지난주")
                        }
                        Button(action: {
                            viewModel.send(.tapFilterOption(.month))
                        }) {
                            if viewModel.state.filterOption == .month {
                                Image(systemName: "checkmark")
                                    .tint(Color.blue)
                            }
                            Text("지난달")
                        }
                        Button(action: {
                            viewModel.send(.tapFilterOption(.year))
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
        .task { viewModel.send(.onAppear) }
    }

    private enum Path: Hashable {
        case detail(Todo)
    }
}
