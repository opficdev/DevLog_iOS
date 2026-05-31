//
//  TodoListView.swift
//  DevLogPresentation
//
//  Created by opfic on 5/30/25.
//

import SwiftUI
import DevLogCore
import DevLogDomain

struct TodoListView: View {
    @Environment(NavigationRouter<HomeRoute>.self) private var router
    @Environment(TodoEditorWindowEvent.self) private var windowEvent
    @Environment(\.diContainer) var container: DIContainer
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openWindow) private var openWindow
    @Environment(\.isiOSAppOnMac) private var isiOSAppOnMac
    @ScaledMetric(relativeTo: .body) private var headerHeight = 41
    @State private var headerOffset: CGFloat = .zero
    @State private var isScrollTrackingEnabled = false
    @State var viewModel: TodoListViewModel

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
                    prompt: Text(
                        String.localizedStringWithFormat(
                            String(localized: "todo_list_search_prompt_format"),
                            TodoCategoryItem(from: viewModel.category).localizedName
                        )
                    )
                )
            }
        }
        .alert(
            viewModel.state.alertTitle,
            isPresented: Binding(
                get: { viewModel.state.showAlert },
                set: { viewModel.send(.setAlert($0)) }
        )) {
            Button(String(localized: "common_close"), role: .cancel) { }
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
        .navigationTitle(TodoCategoryItem(from: viewModel.category).localizedName)
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.state.showEditor },
            set: { viewModel.send(.setShowEditor($0)) }
        )) {
            TodoEditorView(
                viewModel: TodoEditorViewModel(
                    category: viewModel.category,
                    fetchPreferencesUseCase: container.resolve(FetchTodoCategoryPreferencesUseCase.self),
                    fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self)
                ),
                onSubmit: { viewModel.send(.upsertTodo($0)) }
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
                        viewModel.send(.setIsSearching(true))
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
        }
        .background(NavigationBarConfigurator())
        .task { viewModel.send(.onAppear) }
        .onChange(of: windowEvent.submitted) { _, submitted in
            handleTodoEditorSubmit(submitted)
        }
    }

    @ViewBuilder
    private var todoListContent: some View {
        let visibleTodos = viewModel.state.todos.filter { !$0.isHidden }

        ZStack {
            List {
                Group {
                    if visibleTodos.isEmpty, !viewModel.state.isLoading {
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
            .scrollDisabled(visibleTodos.isEmpty || viewModel.state.isLoading)

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
                prompt: Text(
                    String.localizedStringWithFormat(
                        String(localized: "todo_list_search_prompt_format"),
                        TodoCategoryItem(from: viewModel.category).localizedName
                    )
                )
            )
    }

    private func openTodoEditor() {
        if isiOSAppOnMac {
            openWindow(
                id: TodoEditorWindowValue.sceneId,
                value: TodoEditorWindowValue(todoCategory: viewModel.category, source: .list)
            )
        } else {
            viewModel.send(.setShowEditor(true))
        }
    }

    private func handleTodoEditorSubmit(_ submit: TodoEditorWindowSubmit?) {
        guard let submit,
              submit.value.matchesCreate(category: viewModel.category, source: .list) else { return }
        viewModel.send(.upsertTodo(submit.todo))
    }

    @ViewBuilder
    private var searchResultsContent: some View {
        let searchResults = viewModel.state.searchResults.filter { !$0.isHidden }
        let limit = viewModel.searchResultsLimit
        let displayedTodos = viewModel.state.showAllSearchResults
            ? searchResults
            : Array(searchResults.prefix(limit))

        if viewModel.state.searchText.isEmpty {
            Text(
                String.localizedStringWithFormat(
                    String(localized: "todo_list_search_instruction_format"),
                    TodoCategoryItem(from: viewModel.category).localizedName
                )
            )
                .foregroundStyle(Color.gray)
                .frame(maxWidth: .infinity)
        } else if viewModel.state.isLoading {
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

                    if !viewModel.state.showAllSearchResults, limit < searchResults.count {
                        Button(String(localized: "todo_list_show_more")) {
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
                        Text(
                            String.localizedStringWithFormat(
                                String(localized: "todo_list_filters_applied_format"),
                                Int64(viewModel.appliedFilterCount)
                            )
                        )
                        Button(role: .destructive) {
                            viewModel.send(.resetFilters)
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
                get: { viewModel.state.query.sortTarget },
                set: { viewModel.send(.setSortTarget($0)) }
            )) {
                ForEach([TodoQuery.SortTarget.createdAt, .updatedAt], id: \.self) { option in
                    Text(option.title).tag(option)
                }
            } label: {
                Text(String(localized: "todo_list_sort_by"))
            }
            Picker(selection: Binding(
                get: { viewModel.state.query.sortOrder },
                set: { viewModel.send(.setSortOrder($0)) }
            )) {
                ForEach([TodoQuery.SortOrder.latest, .oldest], id: \.self) { option in
                    Text(option.title).tag(option)
                }
            } label: {
                Text(String(localized: "todo_list_sort_order"))
            }
        } label: {
            let condition = viewModel.state.query.sortTarget == .createdAt && viewModel.state.query.sortOrder == .latest
            HStack {
                Text(
                    String.localizedStringWithFormat(
                        String(localized: "todo_list_sort_format"),
                        viewModel.state.query.sortTarget.title,
                        viewModel.state.query.sortOrder.title
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
                get: { viewModel.state.query.isPinned == true },
                set: { _ in viewModel.send(.togglePinnedOnly) }
            )) {
                Text(String(localized: "todo_pinned"))
            }

            Picker(selection: Binding(
                get: { viewModel.state.query.completionFilter },
                set: { viewModel.send(.setCompletionFilter($0)) }
            )) {
                ForEach([TodoQuery.CompletionFilter.all, .incomplete, .completed], id: \.self) { option in
                    Text(option.title).tag(option)
                }
            } label: {
                Text(String(localized: "todo_list_completion_status"))
            }
        } label: {
            let condition = viewModel.state.query.isPinned == true || viewModel.state.query.completionFilter != .all
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

        return Text("\(viewModel.appliedFilterCount)")
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
