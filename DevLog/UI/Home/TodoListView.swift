//
//  TodoListView.swift
//  DevLog
//
//  Created by opfic on 5/30/25.
//

import SwiftUI

struct TodoListView: View {
    @State var viewModel: TodoListViewModel
    @Environment(NavigationRouter.self) var router
    @Environment(\.diContainer) var container: DIContainer
    @Environment(\.colorScheme) private var colorScheme
    @State private var headerOffset: CGFloat = 0
    @State private var headerHeight: CGFloat = .pi
    @State private var isScrollTrackingEnabled = false

    var body: some View {
        Group {
            if #available(iOS 18, *) {
                if viewModel.state.isSearching {
                    todoSearchContent
                } else {
                    todoListContent
                }
            } else {
                Group {
                    if viewModel.state.isSearching {
                        searchResultsContent
                    } else {
                        todoListContent
                    }
                }
                .searchable(
                    text: Binding(
                        get: { viewModel.state.searchText },
                        set: { viewModel.send(.setSearchText($0)) }
                    ),
                    isPresented: Binding(
                        get: { viewModel.state.isSearching },
                        set: { viewModel.send(.setIsSearching($0)) }
                    ),
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "\(viewModel.state.category.localizedName) 검색"
                )
            }
        }
        .navigationDestination(for: Path.self) { path in
            switch path {
            case .detail(let todoId):
                TodoDetailView(viewModel: TodoDetailViewModel(
                    fetchTodoUseCase: container.resolve(FetchTodoByIdUseCase.self),
                    fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
                    upsertUseCase: container.resolve(UpsertTodoUseCase.self),
                    todoId: todoId
                ))
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
            action: { viewModel.send(.undoDelete) }
        ) {
            Label(viewModel.state.toastMessage, systemImage: "arrow.uturn.left")
        }
        .navigationTitle(viewModel.state.category.localizedName)
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.state.showEditor },
            set: { viewModel.send(.setShowEditor($0)) }
        )) {
            TodoEditorView(
                viewModel: TodoEditorViewModel(
                    category: viewModel.state.category,
                    fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self)
                ),
                onSubmit: { viewModel.send(.upsertTodo($0)) }
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.send(.setShowEditor(true))
                } label: {
                    Image(systemName: "plus")
                }
            }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            if #available(iOS 18, *) {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.send(.setIsSearching(true))
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
        }
        .background(NavigationBarConfigurator())
        .task { viewModel.send(.onAppear) }
    }

    private var todoListContent: some View {
        ZStack {
            List {
                Group {
                    if viewModel.state.todos.isEmpty, !viewModel.state.isLoading {
                        HStack {
                            Spacer()
                            Text("작성된 내용이 없습니다.")
                                .foregroundStyle(Color.gray)
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    } else {
                        let todos = viewModel.state.todos
                        ForEach(Array(zip(todos.indices, todos)), id: \.1.id) { idx, todo in
                            Button {
                                router.push(Path.detail(todo.id))
                            } label: {
                                TodoItemRow(todo)
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .alignmentGuide(.listRowSeparatorLeading) { _ in return 0 }
                            .overlay(alignment: .top) {
                                if #available(iOS 26.0, *) {
                                    if idx == 0 {
                                        Divider()
                                            .padding(.horizontal, -16)
                                    }
                                }
                            }
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
                }
                .listRowBackground(Color.clear)
                .listSectionSeparator(.hidden, edges: .top)
            }
            .listStyle(.plain)
            .onScrollOffsetChange { offset in
                guard isScrollTrackingEnabled else { return }
                headerOffset = max(0, -offset)
            }
            .safeAreaInset(edge: .top) {
                VStack(spacing: 4) {
                    headerView
                    if #unavailable(iOS 26) {
                        Divider()
                            .padding(.horizontal, -16)
                    }
                }
                .background {
                    if #available(iOS 26.0, *) {
                        Color.clear
                    } else {
                        Color(.systemBackground)
                    }
                }
                .offset(y: headerOffset)
            }
            .refreshable { viewModel.send(.refresh) }
            .scrollDisabled(viewModel.state.todos.isEmpty || viewModel.state.isLoading)

            if viewModel.state.isLoading {
                LoadingView()
            }
        }
    }

    @available(iOS 18, *)
    private var todoSearchContent: some View {
        searchResultsContent
            .searchable(
                text: Binding(
                    get: { viewModel.state.searchText },
                    set: { viewModel.send(.setSearchText($0)) }
                ),
                isPresented: Binding(
                    get: { viewModel.state.isSearching },
                    set: { viewModel.send(.setIsSearching($0)) }
                ),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "\(viewModel.state.category.localizedName) 검색"
            )
    }

    @ViewBuilder
    private var searchResultsContent: some View {
        let searchResults = viewModel.state.searchResults
        let limit = viewModel.searchResultsLimit
        let displayedTodos = viewModel.state.showAllSearchResults
            ? searchResults
            : Array(searchResults.prefix(limit))

        if viewModel.state.searchText.isEmpty {
            Text("\(viewModel.state.category.localizedName)의 제목이나 내용을 검색해 보세요.")
                .foregroundStyle(Color.gray)
                .frame(maxWidth: .infinity)
        } else if viewModel.state.isLoading {
            LoadingView()
        } else if searchResults.isEmpty {
            Spacer()
            Text("검색 결과가 없습니다.")
                .foregroundStyle(Color.gray)
                .frame(maxWidth: .infinity)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(displayedTodos) { todo in
                        Button {
                            router.push(Path.detail(todo.id))
                        } label: {
                            VStack(spacing: 0) {
                                TodoItemRow(todo)
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    if !viewModel.state.showAllSearchResults, limit < searchResults.count {
                        Button("더보기") {
                            viewModel.send(.setShowAllSearchResults(true))
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                    }
                }
            }
        }
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
            // iOS 26.4부터 헤더의 높이가 달라져서 리스트에서 필터링된 Todo가 없으면 사라지는 현상 해결
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            headerHeight = geometry.size.height.rounded()
                        }
                        .onChange(of: geometry.size.height) { _, height in
                            headerHeight = height.rounded()
                        }
                }
            }
        }
        .scrollIndicators(.never)
        .scrollDisabled(!isScrollTrackingEnabled)
        .contentMargins(.leading, 16, for: .scrollContent)
        .frame(height: headerHeight)
        .onAppear {
            headerOffset = 0
            isScrollTrackingEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isScrollTrackingEnabled = true
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            Picker(selection: Binding(
                get: { viewModel.state.query.sortTarget },
                set: { viewModel.send(.setSortTarget($0)) }
            )) {
                ForEach([TodoQuery.SortTarget.createdAt, .updatedAt], id: \.self) { option in
                    Text(option.title).tag(option)
                }
            } label: {
                Text("정렬 기준")
            }
            Picker(selection: Binding(
                get: { viewModel.state.query.sortOrder },
                set: { viewModel.send(.setSortOrder($0)) }
            )) {
                ForEach([TodoQuery.SortOrder.latest, .oldest], id: \.self) { option in
                    Text(option.title).tag(option)
                }
            } label: {
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
            Toggle(isOn: Binding(
                get: { viewModel.state.query.isPinned == true },
                set: { _ in viewModel.send(.togglePinnedOnly) }
            )) {
                Text("중요 표시")
            }

            Picker(selection: Binding(
                get: { viewModel.state.query.completionFilter },
                set: { viewModel.send(.setCompletionFilter($0)) }
            )) {
                ForEach([TodoQuery.CompletionFilter.all, .incomplete, .completed], id: \.self) { option in
                    Text(option.title).tag(option)
                }
            } label: {
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

private enum Path: Hashable {
        case detail(String)
    }
}
