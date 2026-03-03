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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            List {
                Section {
                    if viewModel.state.todos.isEmpty, !viewModel.state.isLoading {
                        HStack {
                            Spacer()
                            Text("작성된 내용이 없습니다.")
                                .foregroundStyle(Color.gray)
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(viewModel.state.todos) { todo in
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
                                Button {
                                    viewModel.send(.tapToggleCompleted(todo))
                                } label: {
                                    Image(systemName: todo.isCompleted ? "arrow.uturn.backward" : "checkmark")
                                }
                                .tint(Color.green)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive, action: {
                                    viewModel.send(.swipeTodo(todo))
                                }) {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    headerView
                }
                .listRowBackground(Color.clear)
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

            if viewModel.state.isLoading {
                LoadingView()
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

    private var headerView: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                if 0 < viewModel.appliedFilterCount {
                    Menu {
                        Text("\(viewModel.appliedFilterCount)개 필터가 적용됨")
                        Button(role: .destructive) {
                            viewModel.send(.resetFilters)
                        } label: {
                            Text("모든 필터 지우기")
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease")
                            filterBadge
                        }
                        .adaptiveButtonStyle()
                    }
                }

                sortMenu
                filterMenu
            }
        }
        .scrollIndicators(.never)
    }

    private var sortMenu: some View {
        Menu {
            Section {
                ForEach([TodoQuery.SortTarget.createdAt, .updatedAt], id: \.self) { option in
                    Button {
                        viewModel.send(.setSortTarget(option))
                    } label: {
                        selectionLabel(
                            title: option.title,
                            isSelected: viewModel.state.query.sortTarget == option
                        )
                    }
                }
            } header: {
                Text("정렬 기준")
            }

            Section {
                ForEach([TodoQuery.SortOrder.latest, .oldest], id: \.self) { option in
                    Button {
                        viewModel.send(.setSortOrder(option))
                    } label: {
                        selectionLabel(
                            title: option.title,
                            isSelected: viewModel.state.query.sortOrder == option
                        )
                    }
                }
            } header: {
                Text("정렬 순서")
            }
        } label: {
            let condition = viewModel.state.query.sortTarget == .createdAt && viewModel.state.query.sortOrder == .latest
            HStack {
                Text("정렬: \(viewModel.state.query.sortTarget.title) / \(viewModel.state.query.sortOrder.title)")
                Image(systemName: "chevron.down")
            }
            .foregroundStyle(condition ? Color(.label) : .white)
            .adaptiveButtonStyle(color: condition ? .clear : .blue)
        }
    }

    private var filterMenu: some View {
        Menu {
            Button {
                viewModel.send(.togglePinnedOnly)
            } label: {
                selectionLabel(
                    title: "중요 표시",
                    isSelected: viewModel.state.query.isPinned == true
                )
            }

            Section {
                ForEach([TodoQuery.CompletionFilter.all, .incomplete, .completed], id: \.self) { option in
                    Button {
                        viewModel.send(.setCompletionFilter(option))
                    } label: {
                        selectionLabel(
                            title: option.title,
                            isSelected: viewModel.state.query.completionFilter == option
                        )
                    }
                }
            } header: {
                Text("완료 상태")
            }
        } label: {
            let condition = viewModel.state.query.isPinned == true || viewModel.state.query.completionFilter != .all
            HStack {
                Text("필터 옵션")
                Image(systemName: "chevron.down")
            }
            .foregroundStyle(condition ? .white : Color(.label))
            .adaptiveButtonStyle(color: condition ? .blue : .clear)
        }
    }

    private var filterBadge: some View {
        let isDark = colorScheme == .dark
        let blue = Color(uiColor: .systemBlue)
        let textColor: Color = isDark ? blue : .white
        let backgroundColor: Color = isDark ? .white : blue

        return Text("\(viewModel.appliedFilterCount)")
            .font(.caption2.weight(.bold))
            .foregroundColor(textColor)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: 20, height: 20)
            .background(Circle().fill(backgroundColor))
    }

    private func selectionLabel(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .tint(.blue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private enum Path: Hashable {
        case detail(String)
    }
}
