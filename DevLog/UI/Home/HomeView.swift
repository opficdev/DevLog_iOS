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
                case .kind(let todoKind):
                    TodoListView(viewModel: TodoListViewModel(
                        fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
                        fetchTodoByIdUseCase: container.resolve(FetchTodoByIdUseCase.self),
                        upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
                        deleteTodoUseCase: container.resolve(DeleteTodoUseCase.self),
                        undoDeleteTodoUseCase: container.resolve(UndoDeleteTodoUseCase.self),
                        kind: todoKind
                    ))
                    .environment(router)
                case .detail(let todoId):
                    TodoDetailView(viewModel: TodoDetailViewModel(
                        fetchUseCase: container.resolve(FetchTodoByIdUseCase.self),
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
                    viewModel: TodoManageViewModel(viewModel.state.todoKindPreferences),
                    onDismiss: { array in
                        viewModel.send(.setPresentation(.reorderTodo, false))
                        withAnimation {
                            viewModel.send(.orderTodoKindPreferences(array))
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
                if let selectedKind = viewModel.state.selectedTodoKind {
                    TodoEditorView(
                        viewModel: TodoEditorViewModel(kind: selectedKind),
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
            let preferences = viewModel.state.todoKindPreferences
            ForEach(preferences.filter { $0.isVisible }, id: \.id) { preference in
                let kind = preference.kind
                NavigationLink(value: Path.kind(kind)) {
                    labelImage(
                        text: kind.localizedName,
                        systemName: kind.symbolName,
                        imageColor: kind.color
                    )
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
                            .padding(.vertical, -4)
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
                    let preferences = viewModel.state.todoKindPreferences.filter(\.isVisible)
                    ForEach(preferences, id: \.id) { preference in
                        let kind = preference.kind
                        Button {
                            DispatchQueue.main.async {
                                viewModel.send(.tapTodoKind(kind))
                            }
                        } label: {
                            labelImage(
                                text: kind.localizedName,
                                systemName: kind.symbolName,
                                imageColor: kind.color
                            )
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
        case kind(TodoKind)
        case detail(String)
        case web(WebPageItem)
    }
}

private struct RecentTodoRow: View {
    let todo: RecentTodoItem
    let sceneWidth: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(todo.kind.color)
                .frame(width: sceneWidth * 0.08, height: sceneWidth * 0.08)
                .overlay {
                    Image(systemName: todo.kind.symbolName)
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
                    Text(todo.kind.localizedName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(todo.kind.color)

                    TimelineView(.periodic(from: .now, by: 1.0)) { context in
                        Text(timeAgoText(from: todo.updatedAt, now: context.date))
                            .font(.caption2)
                            .foregroundStyle(Color.gray)
                    }
                }

                if !todo.tags.isEmpty {
                    TagList(todo.tags, lineLimit: 1)
                }
            }
        }
    }

    private func timeAgoText(from date: Date, now: Date) -> String {
        let seconds = Int(now.timeIntervalSince(date))

        if seconds < 60 {
            return "\(max(0, seconds))초 전"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)분 전"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)시간 전"
        } else {
            let days = seconds / 86400
            return "\(days)일 전"
        }
    }
}
