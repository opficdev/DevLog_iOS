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
    @StateObject private var router = NavigationRouter()
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        NavigationStack(path: $router.path) {
            List {
                todoSection
                pinnedSection
                webPageSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("홈")
            .navigationDestination(for: Path.self) { path in
                switch path {
                case .kind(let todoKind):
                    TodoListView(viewModel: TodoListViewModel(
                        fetchTodosByKindUseCase: container.resolve(FetchTodosByKindUseCase.self),
                        fetchTodoByIDUseCase: container.resolve(FetchTodoByIDUseCase.self),
                        upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
                        deleteTodoUseCase: container.resolve(DeleteTodoUseCase.self),
                        kind: todoKind
                    ))
                    .environmentObject(router)
                case .detail(let todoID):
                    TodoDetailView(viewModel: TodoDetailViewModel(
                        fetchUseCase: container.resolve(FetchTodoByIDUseCase.self),
                        upsertUseCase: container.resolve(UpsertTodoUseCase.self),
                        todoID: todoID
                    ))
                case .web(let url):
                    WebView(url: url)
                }
            }
            .toolbar { toolbar }
            .sheet(isPresented: Binding(
                get: { viewModel.state.reorderTodo },
                set: { viewModel.send(.setReorderTodo($0)) }
            )) {
                TodoManageView(
                    viewModel: TodoManageViewModel(viewModel.state.todoKindPreferences),
                    onDismiss: { array in
                        viewModel.send(.setReorderTodo(false))
                        withAnimation {
                            viewModel.send(.orderTodoKindPreferences(array))
                        }
                    }
                )
            }
            .sheet(isPresented: Binding(
                get: { viewModel.state.showTodoKindPicker },
                set: { viewModel.send(.setShowContentPicker($0)) }
            )) {
                contentPicker
            }
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.state.showTodoEditor },
                set: { viewModel.send(.setShowTodoEditor($0)) }
            )) {
                if let selectedKind = viewModel.state.selectedTodoKind {
                    TodoEditorView(
                        viewModel: TodoEditorViewModel(kind: selectedKind),
                        onSubmit: { viewModel.send(.upsertTodo($0)) }
                    )
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.state.showSearchView },
                set: { viewModel.send(.setShowSearchView($0)) }
            )) {
                SearchView(viewModel: SearchViewModel(
                    fetchWebPagesUseCase: container.resolve(FetchWebPagesUseCase.self),
                    fetchTodosByKeywordUseCase: container.resolve(FetchTodosByKeywordUseCase.self)
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
            .onAppear {
                viewModel.send(.onAppear)
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
            .autocorrectionDisabled()
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
                    viewModel.send(.setReorderTodo(true))
                }) {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundStyle(Color.gray)
                }
            }
            .listRowInsets(EdgeInsets())    //  헤더의 padding 제거
        })
    }

    private var pinnedSection: some View {
        Section(content: {
            if viewModel.state.pinnedTodos.isEmpty {
                if viewModel.state.isLoading {
                    LoadingView(isClear: true)
                } else {
                    HStack {
                        Spacer()
                        Text("최근에 중요 표시를 한 Todo가 여기 표시됩니다.")
                            .font(.callout)
                        Spacer()
                    }
                }
            } else {
                ForEach(viewModel.state.pinnedTodos, id: \.id) { todo in
                    NavigationLink(value: Path.detail(todo.id)) {
                        HStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(todo.kind.color)
                                .frame(width: sceneWidth * 0.08, height: sceneWidth * 0.08)
                                .overlay {
                                    Image(systemName: todo.kind.symbolName)
                                        .foregroundStyle(Color.white)
                                        .font(.title3)
                                }
                            VStack(alignment: .leading) {
                                Text(todo.title)
                                    .bold()
                                    .foregroundStyle(Color.primary)
                                Text(todo.dueDate?
                                    .formatted(date: .abbreviated, time: .omitted) ?? "마감일 없음"
                                )
                                .font(.caption2)
                                .foregroundStyle(Color.gray)
                            }
                        }
                        .padding(.vertical, -6)
                    }
                }
            }
        }, header: {
            HStack {
                Text("중요 표시")
                    .foregroundStyle(Color.primary)
                    .font(.title2.bold())
                Spacer()

            }
            .listRowInsets(EdgeInsets())
        })
    }

    private var webPageSection: some View {
        Section {
            ForEach(viewModel.state.webPages, id: \.id) { page in
                webResultRow(page)
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
                viewModel.send(.setShowContentPicker(true))
            } label: {
                Image(systemName: "plus")
            }
        }
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                viewModel.send(.setShowSearchView(true))
            } label: {
                Image(systemName: "magnifyingglass")
            }
        }
    }

    private func webResultRow(_ item: WebPageItem) -> some View {
        Button {
            router.push(Path.web(item.url))
        } label: {
            HStack {
                CacheableImage(url: item.imageURL) {
                    Image(systemName: "globe")
                        .resizable()
                        .scaledToFit()
                }
                .frame(width: sceneWidth / 10, height: sceneWidth / 10)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading) {
                    Text(item.title)
                        .foregroundStyle(Color.primary)
                        .bold()
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    Text(item.displayURL)
                        .foregroundStyle(Color.accentColor)
                        .underline()
                }
                Spacer()
            }
            .padding(.vertical, 4)
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
                            viewModel.send(.tapTodoKind(kind))
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
                        viewModel.send(.setAlert(isPresented: true, type: .webPageInput))
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
                        viewModel.send(.setShowContentPicker(false))
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
        case web(URL)
    }
}
