//
//  TodoListView.swift
//  DevLog
//
//  Created by opfic on 5/30/25.
//

import SwiftUI

struct TodoListView: View {
    @StateObject var viewModel: TodoListViewModel
    @EnvironmentObject var router: NavigationRouter
    @Environment(\.diContainer) var container: DIContainer

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
                            router.push(Path.detail(todo.id))
                        } label: {
                            TodoItemRow(todo)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .alignmentGuide(.listRowSeparatorLeading) { _ in return 0 }
                        .onAppear {
                            let lastID = viewModel.state.todos.last?.id
                            if todo.id == lastID, viewModel.state.hasMore {
                                viewModel.send(.loadNextPage)
                            }
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
                            Button(action: {
                                viewModel.send(.tapToggleCompleted(todo))
                            }) {
                                Image(systemName: todo.isCompleted ? "arrow.uturn.backward" : "checkmark")
                            }
                            .tint(Color.green)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        viewModel.send(.refresh)
                    }
                    .navigationDestination(for: Path.self) { path in
                        switch path {
                        case .detail(let todoID):
                            TodoDetailView(viewModel: TodoDetailViewModel(
                                fetchUseCase: container.resolve(FetchTodoByIDUseCase.self),
                                upsertUseCase: container.resolve(UpsertTodoUseCase.self),
                                todoID: todoID
                            ))
                        }
                    }
                }
            }
        }
        .alert(
            viewModel.state.alertTitle,
            isPresented: Binding(
                get: { viewModel.state.showAlert },
                set: { viewModel.send(.setAlert($0)) }
        )) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.state.alertMessage)
        }
        .toast(
            isPresented: Binding(
                get: { viewModel.state.showToast },
                set: { viewModel.send(.setToast(isPresented: $0)) }
            ),
            duration: 5,
            action: { viewModel.send(.undoDelete) },
            onDismiss: { viewModel.send(.confirmDelete) }
        ) {
            Label(viewModel.state.toastMessage, systemImage: "arrow.uturn.left")
        }
        .navigationTitle(viewModel.state.kind.localizedName)
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.state.showEditor },
            set: { viewModel.send(.setShowEditor($0)) }
        )) {
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
                Button {
                    viewModel.send(.setShowEditor(true))
                } label: {
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
        case detail(String)
    }
}
