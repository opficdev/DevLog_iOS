//
//  SearchView.swift
//  DevLogPresentation
//
//  Created by 최윤진 on 2/12/26.
//

import SwiftUI
import DevLogCore
import DevLogDomain

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.diContainer) private var container: DIContainer
    @State private var router = NavigationRouter<Path>()
    @State var viewModel: SearchViewModel

    var body: some View {
        NavigationStack(path: $router.path) {
            searchableContent
                .navigationDestination(for: Path.self) { path in
                    switch path {
                    case .todo(let todoId):
                        TodoDetailView(viewModel: TodoDetailViewModel(
                            fetchTodoUseCase: container.resolve(FetchTodoByIdUseCase.self),
                            fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
                            upsertUseCase: container.resolve(UpsertTodoUseCase.self),
                            todoId: todoId
                        ))
                    case .web(let page):
                        WebView(url: page.url)
                            .ignoresSafeArea()
                            .toolbar {
                                ToolbarItem(placement: .principal) {
                                    Text(page.title)
                                        .bold()
                                }
                            }
                    }
                }
                .onAppear {
                    DispatchQueue.main.async {
                        viewModel.send(.setSearching(true))
                    }
                }
                .onChange(of: viewModel.state.isSearching) { _, isSearching in
                    if !isSearching {
                        dismiss()
                    }
                }
                .alert(viewModel.state.alertTitle, isPresented: Binding(
                    get: { viewModel.state.showAlert },
                    set: { viewModel.send(.setAlert($0)) }
                )) {
                    Button(String(localized: "common_close"), role: .cancel) { }
                } message: {
                    Text(viewModel.state.alertMessage)
                }
        }
    }

    @ViewBuilder
    private var searchableContent: some View {
        Group {
            if viewModel.state.searchQuery.isEmpty {
                if viewModel.state.recentQueries.isEmpty {
                    searchInstruction
                } else {
                    ScrollView {
                        recentQueries
                    }
                }
            } else if viewModel.state.isLoading {
                LoadingView()
            } else if viewModel.state.webPages.isEmpty && viewModel.state.todos.isEmpty {
                emptySearchResult
            } else {
                ScrollView {
                    searchResults
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .searchable(
            text: Binding(
                get: { viewModel.state.searchQuery },
                set: { viewModel.send(.setSearchQuery($0)) }
            ),
            isPresented: Binding(
                get: { viewModel.state.isSearching },
                set: { viewModel.send(.setSearching($0)) }
            ),
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text(String(localized: "search_prompt"))
        )
        .onSubmit(of: .search) {
            viewModel.send(.addRecentQuery(viewModel.state.searchQuery))
        }
    }

    private var searchInstruction: some View {
        VStack {
            Spacer()
            Text(String(localized: "search_instruction"))
                .foregroundStyle(Color.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptySearchResult: some View {
        VStack {
            Spacer()
            Text(String(localized: "search_empty"))
                .foregroundStyle(Color.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !viewModel.state.todos.isEmpty {
                todoResults
            }
            if !viewModel.state.webPages.isEmpty {
                webPages
            }
        }
        .padding(.vertical, 8)
    }

    private var todoResults: some View {
        let limit = viewModel.contentsLimit
        let todos = viewModel.state.showAllTodos
            ? viewModel.state.todos
            : Array(viewModel.state.todos.prefix(limit))

        return VStack(alignment: .leading, spacing: 12) {
            Text("Todos")
                .font(.headline)
                .foregroundStyle(Color(.label))
            Divider()
            LazyVStack(spacing: 0) {
                ForEach(todos, id: \.id) { todo in
                    todoResultRow(todo)
                }
            }
            .padding(.top, -12)
            if !viewModel.state.showAllTodos && limit < viewModel.state.todos.count {
                Button(String(localized: "search_show_more")) {
                    viewModel.send(.setShowAllTodos(true))
                }
                .font(.subheadline)
                .foregroundStyle(Color.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
    }

    private var webPages: some View {
        let limit = viewModel.contentsLimit
        let pages = viewModel.state.showAllWebPages
            ? viewModel.state.webPages
            : Array(viewModel.state.webPages.prefix(limit))

        return VStack(alignment: .leading, spacing: 12) {
            Text("Web Pages")
                .font(.headline)
                .foregroundStyle(Color(.label))
            Divider()
            LazyVStack(spacing: 0) {
                ForEach(pages, id: \.id) { page in
                    webResultRow(page)
                }
            }
            .padding(.top, -12)
            if !viewModel.state.showAllWebPages && limit < viewModel.state.webPages.count {
                Button(String(localized: "search_show_more")) {
                    viewModel.send(.setShowAllWebPages(true))
                }
                .font(.subheadline)
                .foregroundStyle(Color.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
    }

    private func todoResultRow(_ item: TodoListItem) -> some View {
        Button {
            router.push(Path.todo(item.id))
        } label: {
            VStack(spacing: 0) {
                TodoItemRow(item)
                Divider()
            }
        }
    }

    private func webResultRow(_ item: WebPageItem) -> some View {
        NavigationLink(value: Path.web(item)) {
            VStack(spacing: 0) {
                WebItemRow(item: item, showsChevron: true)
                Divider()
            }
        }
    }

    private var recentQueries: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "search_recent"))
                    .font(.headline)
                    .foregroundStyle(Color(.label))
                Spacer()
                Button(String(localized: "search_clear_all")) {
                    viewModel.send(.clearRecentQueries)
                }
                .font(.subheadline)
                .foregroundStyle(Color.gray)
            }

            ForEach(viewModel.state.recentQueries, id: \.self) { query in
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(Color.gray)
                    Text(query)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Button {
                        viewModel.send(.removeRecentQuery(query))
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.gray)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.send(.setSearchQuery(query))
                    viewModel.send(.setSearching(true))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private enum Path: Hashable {
        case todo(String)
        case web(WebPageItem)
    }
}
