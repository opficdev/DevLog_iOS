//
//  TodoListView.swift
//  DevLogPresentation
//
//  Created by opfic on 5/30/25.
//

import SwiftUI
import ComposableArchitecture
import DevLogCore
import DevLogDomain

struct TodoListView: View {
    @Environment(NavigationRouter<HomeRoute>.self) private var router
    @Environment(\.diContainer) var container: DIContainer
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openWindow) private var openWindow
    @Environment(\.isiOSAppOnMac) private var isiOSAppOnMac
    @ScaledMetric(relativeTo: .body) private var headerHeight = 41
    @State private var headerOffset: CGFloat = .zero
    @State private var isScrollTrackingEnabled = false
    @State var store: StoreOf<TodoListFeature>

    var body: some View {
        Group {
            if #available(iOS 18, *) {
                if store.state.isSearching {
                    todoSearchContent
                } else {
                    todoListContent
                }
            } else {
                Group {
                    if store.state.isSearching {
                        searchResultsContent
                    } else {
                        todoListContent
                    }
                }
                .searchable(
                    text: Binding(
                        get: { store.state.searchText },
                        set: { store.send(.setSearchText($0)) }
                    ),
                    isPresented: Binding(
                        get: { store.state.isSearching },
                        set: { store.send(.setIsSearching($0)) }
                    ),
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: Text(
                        String.localizedStringWithFormat(
                            String(localized: "todo_list_search_prompt_format"),
                            TodoCategoryItem(from: store.category).localizedName
                        )
                    )
                )
            }
        }
        .alert(
            store.state.alertTitle,
            isPresented: Binding(
                get: { store.state.showAlert },
                set: { store.send(.setAlert($0)) }
        )) {
            Button(String(localized: "common_close"), role: .cancel) { }
        } message: {
            Text(store.state.alertMessage)
        }
        .navigationTitle(TodoCategoryItem(from: store.category).localizedName)
        .fullScreenCover(isPresented: Binding(
            get: { store.state.showEditor },
            set: { store.send(.setShowEditor($0)) }
        )) {
            TodoEditorView(
                store: Store(initialState: TodoEditorFeature.State(category: store.category)) {
                    TodoEditorFeature()
                } withDependencies: {
                    $0.fetchTodoCategoryPreferencesUseCase = container.resolve(FetchTodoCategoryPreferencesUseCase.self)
                    $0.fetchReferenceItemsUseCase = container.resolve(FetchReferenceItemsUseCase.self)
                    $0.upsertTodoUseCase = container.resolve(UpsertTodoUseCase.self)
                    $0.trackAnalyticsEventUseCase = container.resolve(TrackAnalyticsEventUseCase.self)
                },
                onCreateSuccess: {
                    store.send(.setShowEditor(false))
                    store.send(.refresh)
                }
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    openTodoEditor()
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
                        store.send(.setIsSearching(true))
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
        }
        .background(NavigationBarConfigurator())
        .background(Color(.systemGroupedBackground))
        .task { store.send(.onAppear) }
        .onChange(of: store.deleteToastTodoId) { _, todoId in
            guard let todoId else { return }
            presentDeleteTodoToast(todoId)
            store.send(.presentedDeleteToast)
        }
    }

    @ViewBuilder
    private var todoListContent: some View {
        let visibleTodos = store.state.todos.filter { !$0.isHidden }

        ZStack {
            List {
                Group {
                    if visibleTodos.isEmpty, !store.state.isLoading {
                        HStack {
                            Spacer()
                            Text(String(localized: "todo_list_empty"))
                                .foregroundStyle(Color.gray)
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(Array(zip(visibleTodos.indices, visibleTodos)), id: \.1.id) { idx, todo in
                            Button {
                                selectTodo(todo.id)
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
                                let lastID = visibleTodos.last?.id
                                if todo.id == lastID, store.state.hasMore {
                                    store.send(.loadNextPage)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button(action: {
                                    store.send(.tapTogglePinned(todo))
                                }) {
                                    Image(systemName: "star\(todo.isPinned ? ".slash" : ".fill")")
                                }
                                .tint(Color.orange)
                                Button {
                                    store.send(.tapToggleCompleted(todo))
                                } label: {
                                    Image(systemName: todo.isCompleted ? "arrow.uturn.backward" : "checkmark")
                                }
                                .tint(Color.green)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive, action: {
                                    store.send(.swipeTodo(todo))
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
                        Color(.systemGroupedBackground)
                    }
                }
                .offset(y: headerOffset)
            }
            .refreshable { store.send(.refresh) }
            .scrollDisabled(visibleTodos.isEmpty || store.state.isLoading)

            if store.state.isLoading {
                LoadingView()
            }
        }
    }

    @available(iOS 18, *)
    private var todoSearchContent: some View {
        searchResultsContent
            .searchable(
                text: Binding(
                    get: { store.state.searchText },
                    set: { store.send(.setSearchText($0)) }
                ),
                isPresented: Binding(
                    get: { store.state.isSearching },
                    set: { store.send(.setIsSearching($0)) }
                ),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text(
                    String.localizedStringWithFormat(
                        String(localized: "todo_list_search_prompt_format"),
                        TodoCategoryItem(from: store.category).localizedName
                    )
                )
            )
    }

    private func openTodoEditor() {
        if isiOSAppOnMac {
            openWindow(
                id: TodoEditorWindowValue.sceneId,
                value: TodoEditorWindowValue(todoCategory: store.category, source: .list)
            )
        } else {
            store.send(.setShowEditor(true))
        }
    }

    private func presentDeleteTodoToast(_ todoId: String) {
        ToastPresenter.present(
            message: String(localized: "common_undo"),
            systemImage: "arrow.uturn.left",
            duration: 5,
            action: {
                store.send(.undoDelete)
            },
            onDismiss: {
                store.send(.finishDeleteToast(todoId))
            }
        )
    }

    @ViewBuilder
    private var searchResultsContent: some View {
        let searchResults = store.state.searchResults.filter { !$0.isHidden }
        let limit = store.searchResultsLimit
        let displayedTodos = store.state.showAllSearchResults
            ? searchResults
            : Array(searchResults.prefix(limit))

        if store.state.searchText.isEmpty {
            Text(
                String.localizedStringWithFormat(
                    String(localized: "todo_list_search_instruction_format"),
                    TodoCategoryItem(from: store.category).localizedName
                )
            )
                .foregroundStyle(Color.gray)
                .frame(maxWidth: .infinity)
        } else if store.state.isLoading {
            LoadingView()
        } else if searchResults.isEmpty {
            Spacer()
            Text(String(localized: "todo_list_search_empty"))
                .foregroundStyle(Color.gray)
                .frame(maxWidth: .infinity)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(displayedTodos) { todo in
                        Button {
                            selectTodo(todo.id)
                        } label: {
                            VStack(spacing: 0) {
                                TodoItemRow(todo)
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    if !store.state.showAllSearchResults, limit < searchResults.count {
                        Button(String(localized: "todo_list_show_more")) {
                            store.send(.setShowAllSearchResults(true))
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
                if 0 < store.appliedFilterCount {
                    Menu {
                        Text(
                            String.localizedStringWithFormat(
                                String(localized: "todo_list_filters_applied_format"),
                                Int64(store.appliedFilterCount)
                            )
                        )
                        Button(role: .destructive) {
                            store.send(.resetFilters)
                        } label: {
                            Text(String(localized: "todo_list_clear_filters"))
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
                get: { store.state.query.sortTarget },
                set: { store.send(.setSortTarget($0)) }
            )) {
                ForEach([TodoQuery.SortTarget.createdAt, .updatedAt], id: \.self) { option in
                    Text(option.title).tag(option)
                }
            } label: {
                Text(String(localized: "todo_list_sort_by"))
            }
            Picker(selection: Binding(
                get: { store.state.query.sortOrder },
                set: { store.send(.setSortOrder($0)) }
            )) {
                ForEach([TodoQuery.SortOrder.latest, .oldest], id: \.self) { option in
                    Text(option.title).tag(option)
                }
            } label: {
                Text(String(localized: "todo_list_sort_order"))
            }
        } label: {
            let condition = store.state.query.sortTarget == .createdAt && store.state.query.sortOrder == .latest
            HStack {
                Text(
                    String.localizedStringWithFormat(
                        String(localized: "todo_list_sort_format"),
                        store.state.query.sortTarget.title,
                        store.state.query.sortOrder.title
                    )
                )
                Image(systemName: "chevron.down")
            }
            .foregroundStyle(condition ? Color(.label) : .white)
            .adaptiveButtonStyle(color: condition ? .clear : .blue)
        }
    }

    private var filterMenu: some View {
        Menu {
            Toggle(isOn: Binding(
                get: { store.state.query.isPinned == true },
                set: { _ in store.send(.togglePinnedOnly) }
            )) {
                Text(String(localized: "todo_pinned"))
            }

            Picker(selection: Binding(
                get: { store.state.query.completionFilter },
                set: { store.send(.setCompletionFilter($0)) }
            )) {
                ForEach([TodoQuery.CompletionFilter.all, .incomplete, .completed], id: \.self) { option in
                    Text(option.title).tag(option)
                }
            } label: {
                Text(String(localized: "todo_list_completion_status"))
            }
        } label: {
            let condition = store.state.query.isPinned == true || store.state.query.completionFilter != .all
            HStack {
                Text(String(localized: "todo_list_filter_options"))
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

        return Text("\(store.appliedFilterCount)")
            .font(.caption2.weight(.bold))
            .foregroundColor(textColor)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: 20, height: 20)
            .background(Circle().fill(backgroundColor))
    }

    private func selectTodo(_ todoId: String) {
        router.push(.todo(TodoIdItem(id: todoId)))
    }
}
