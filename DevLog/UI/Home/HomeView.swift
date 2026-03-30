//
//  HomeView.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.diContainer) var container: any DIContainer
    @Environment(\.sceneWidth) var sceneWidth: CGFloat
    @State private var router = NavigationRouter()
    @State var viewModel: HomeViewModel

    var body: some View {
        NavigationStack(path: $router.path) {
            List {
                todoSection
                recentTodoSection
                webPageSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("홈")
            .navigationDestination(for: Path.self) { path in
                switch path {
                case .category(let item):
                    TodoListView(viewModel: TodoListViewModel(
                        fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
                        fetchTodoByIdUseCase: container.resolve(FetchTodoByIdUseCase.self),
                        upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
                        deleteTodoUseCase: container.resolve(DeleteTodoUseCase.self),
                        undoDeleteTodoUseCase: container.resolve(UndoDeleteTodoUseCase.self),
                        category: item.todoCategory
                    ))
                    .environment(router)
                case .detail(let todoId):
                    TodoDetailView(viewModel: TodoDetailViewModel(
                        fetchTodoUseCase: container.resolve(FetchTodoByIdUseCase.self),
                        fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
                        upsertUseCase: container.resolve(UpsertTodoUseCase.self),
                        todoId: todoId
                    ))
                case .web(let page):
                    WebView(url: page.url)
                        .navigationBarTitleDisplayMode(.inline)
                        .ignoresSafeArea()
                        .toolbar(.hidden, for: .tabBar)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text(page.title)
                                    .bold()
                            }
                        }
                }
            }
            .toolbar { toolbar }
            .sheet(isPresented: Binding(
                get: { viewModel.state.reorderTodo },
                set: { viewModel.send(.setPresentation(.reorderTodo, $0)) }
            )) {
                TodoManageView(
                    viewModel: TodoManageViewModel(viewModel.state.preferences),
                    onDismiss: { array in
                        viewModel.send(.setPresentation(.reorderTodo, false))
                        withAnimation {
                            viewModel.send(.orderTodoCategoryPreferences(array))
                        }
                    }
                )
            }
            .sheet(isPresented: Binding(
                get: { viewModel.state.showContentPicker },
                set: { _, _ in }
            )) {
                contentPicker
            }
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.state.showTodoEditor },
                set: { viewModel.send(.setPresentation(.todoEditor, $0)) }
            )) {
                if let selectedCategory = viewModel.state.selectedTodoCategory {
                    TodoEditorView(
                        viewModel: TodoEditorViewModel(
                            category: selectedCategory,
                            fetchPreferencesUseCase: container.resolve(FetchTodoCategoryPreferencesUseCase.self),
                            fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self)
                        ),
                        onSubmit: { viewModel.send(.addTodo($0)) }
                    )
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.state.showSearchView },
                set: { viewModel.send(.setPresentation(.searchView, $0)) }
            )) {
                SearchView(viewModel: SearchViewModel(
                    fetchWebPagesUseCase: container.resolve(FetchWebPagesUseCase.self),
                    fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
                    fetchRecentSearchQueriesUseCase: container.resolve(FetchRecentSearchQueriesUseCase.self),
                    updateRecentSearchQueriesUseCase: container.resolve(UpdateRecentSearchQueriesUseCase.self)
                ))
            }
            .alert(
                viewModel.state.alertTitle,
                isPresented: Binding(
                    get: { viewModel.state.showAlert },
                    set: { viewModel.send(.setAlert(isPresented: $0)) }
                )
            ) {
                alertButtons
            } message: {
                Text(viewModel.state.alertMessage)
            }
            .toast(
                isPresented: Binding(
                    get: { viewModel.state.showToast },
                    set: { viewModel.send(.setToast(isPresented: $0)) }
                ),
                duration: 5,
                action: { viewModel.send(.undoDeleteWebPage) }
            ) {
                Label(viewModel.state.toastMessage, systemImage: "arrow.uturn.left")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .onAppear {
                viewModel.send(.onAppear)
            }
            .overlay {
                if viewModel.state.isAppending {
                    LoadingView()
                }
            }
        }
    }

    @ViewBuilder
    private var alertButtons: some View {
        switch viewModel.state.alertType {
        case .webPageInput:
            TextField(
                "https://",
                text: Binding(
                    get: { viewModel.state.webPageURLInput },
                    set: { viewModel.send(.updateWebPageURLInput($0)) }
                )
            )
            .textInputAutocapitalization(.never)
            .keyboardType(.URL)
            Button("추가") {
                viewModel.send(.addWebPage)
            }
            Button("취소", role: .cancel) {
                viewModel.send(.setAlert(isPresented: false))
            }
        case .invalidURL, .error, .none:
            Button("확인", role: .cancel) {
                viewModel.send(.setAlert(isPresented: false))
            }
        }
    }

    private var todoSection: some View {
        Section(content: {
            if viewModel.state.isPreferencesLoading {
                LoadingView()
            } else {
                let preferences = viewModel.state.preferences
                ForEach(preferences.filter { $0.isVisible }, id: \.id) { item in
                    NavigationLink(value: Path.category(item)) {
                        labelImage(
                            text: item.localizedName,
                            systemName: item.symbolName,
                            imageColor: item.color
                        )
                    }
                }
            }
        }, header: {
            HStack {
                Text("TODO")
                    .foregroundStyle(Color.primary)
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: {
                    viewModel.send(.setPresentation(.reorderTodo, true))
                }) {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundStyle(Color.gray)
                }
            }
            .listRowInsets(EdgeInsets())    //  헤더의 padding 제거
        })
    }

    private var recentTodoSection: some View {
        Section {
            if viewModel.state.isRecentTodosLoading {
                LoadingView()
            } else if viewModel.state.recentTodos.isEmpty {
                HStack {
                    Spacer()
                    Text("최근 수정한 Todo가 없습니다.")
                        .font(.callout)
                    Spacer()
                }
            } else {
                ForEach(viewModel.state.recentTodos, id: \.id) { todo in
                    NavigationLink(value: Path.detail(todo.id)) {
                        RecentTodoRow(todo: todo, sceneWidth: sceneWidth)
                    }
                }
            }
        } header: {
            HStack {
                Text("최근 수정")
                    .foregroundStyle(Color.primary)
                    .font(.title2.bold())
                Spacer()
            }
            .listRowInsets(EdgeInsets())
        }
    }

    private var webPageSection: some View {
        Section {
            if viewModel.state.isWebPageLoading {
                LoadingView()
                    .id(UUID()) //  id 부여를 통해 렌더링 강제
            } else if viewModel.state.webPages.isEmpty {
                HStack {
                    Spacer()
                    Text("저장한 Web Page가 표시됩니다.")
                        .font(.callout)
                    Spacer()
                }
            } else {
                ForEach(viewModel.state.webPages, id: \.id) { page in
                    webResultRow(page)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
        } header: {
            HStack {
                Text("Web Page")
                    .foregroundStyle(Color.primary)
                    .font(.title2.bold())
                Spacer()
            }
            .listRowInsets(EdgeInsets())
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.send(.setPresentation(.contentPicker, true))
            } label: {
                Image(systemName: "plus")
            }
            .disabled(!viewModel.state.isNetworkConnected)
        }
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                viewModel.send(.setPresentation(.searchView, true))
            } label: {
                Image(systemName: "magnifyingglass")
            }
        }
    }

    private func webResultRow(_ item: WebPageItem) -> some View {
        NavigationLink(value: Path.web(item)) {
            WebItemRow(item: item, showsChevron: false)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.send(.deleteWebPage(item))
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    private var contentPicker: some View {
        NavigationStack {
            List {
                Section {
                    if viewModel.state.isPreferencesLoading {
                        LoadingView()
                    } else {
                        let preferences = viewModel.state.preferences.filter(\.isVisible)
                        ForEach(preferences, id: \.id) { item in
                            Button {
                                DispatchQueue.main.async {
                                    viewModel.send(.tapTodoCategory(item.category))
                                }
                            } label: {
                                labelImage(
                                    text: item.localizedName,
                                    systemName: item.symbolName,
                                    imageColor: item.color
                                )
                            }
                        }
                    }
                } header: {
                    Text("TODO")
                        .foregroundStyle(Color(.label))
                }

                Section {
                    Button {
                        DispatchQueue.main.async {
                            viewModel.send(.setAlert(isPresented: true, type: .webPageInput))
                        }
                    } label: {
                        labelImage(
                            text: "URL",
                            systemName: "globe",
                            imageColor: .blue
                        )
                    }
                } header: {
                    Text("Web Page")
                        .foregroundStyle(Color(.label))
                }
            }
            .navigationTitle("컨텐츠")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.send(.setPresentation(.contentPicker, false))
                    } label: {
                        Image(systemName: "xmark")
                            .bold()
                    }
                }
            }
        }
    }

    private func labelImage(
        text: String,
        systemName: String,
        imageColor: Color
    ) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(imageColor)
                .frame(width: sceneWidth * 0.08, height: sceneWidth * 0.08)
                .overlay {
                    Image(systemName: systemName)
                        .foregroundStyle(Color.white)
                        .font(.title3)
                }
            Text(text)
                .foregroundStyle(Color.primary)
            Spacer()
        }
        .padding(.vertical, -6)
    }

    private enum Path: Hashable {
        case category(TodoCategoryPreferenceItem)
        case detail(String)
        case web(WebPageItem)
    }
}

private struct RecentTodoRow: View {
    let todo: RecentTodoItem
    let sceneWidth: CGFloat

    var body: some View {
        let todoCategoryItem = TodoCategoryPreferenceItem(from: todo.category)
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(todoCategoryItem.color)
                .frame(width: sceneWidth * 0.08, height: sceneWidth * 0.08)
                .overlay {
                    Image(systemName: todoCategoryItem.symbolName)
                        .foregroundStyle(Color.white)
                        .font(.title3)
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if todo.isPinned {
                        Image(systemName: "star.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                    Text(todo.title)
                        .foregroundStyle(Color.primary)
                        .font(.headline)
                        .lineLimit(1)
                    if let number = todo.number {
                        Text("#\(number)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.gray)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }

                HStack(spacing: 6) {
                    Text(todoCategoryItem.localizedName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(todoCategoryItem.color)

                    RelativeTimeText(date: todo.updatedAt)
                }

                if !todo.tags.isEmpty {
                    TagList(todo.tags, lineLimit: 1)
                }
            }
        }
    }
}
