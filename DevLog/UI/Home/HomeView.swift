//
//  HomeView.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import SwiftUI

struct HomeView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var labelWidth = CGFloat(34)
    let coordinator: HomeViewCoordinator
    let isCompactLayout: Bool

    var body: some View {
        List {
            todoSection
            recentTodoSection
            webPageSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "nav_home"))
        .toolbar { toolbar }
        .sheet(isPresented: Binding(
            get: { coordinator.viewModel.state.reorderTodo },
            set: { coordinator.viewModel.send(.setPresentation(.reorderTodo, $0)) }
        )) {
            TodoManageView(
                viewModel: coordinator.makeTodoManageViewModel(),
                onDismiss: { array in
                    coordinator.viewModel.send(.setPresentation(.reorderTodo, false))
                    withAnimation {
                        coordinator.viewModel.send(.orderTodoCategory(array))
                    }
                }
            )
        }
        .sheet(isPresented: Binding(
            get: { coordinator.viewModel.state.showContentPicker },
            set: { _, _ in }
        )) {
            contentPicker
        }
        .fullScreenCover(isPresented: Binding(
            get: { coordinator.viewModel.state.showTodoEditor },
            set: { coordinator.viewModel.send(.setPresentation(.todoEditor, $0)) }
        )) {
            if let selectedCategory = coordinator.viewModel.state.selectedTodoCategory {
                TodoEditorView(
                    viewModel: coordinator.makeTodoEditorViewModel(category: selectedCategory),
                    onSubmit: { coordinator.viewModel.send(.addTodo($0)) }
                )
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { coordinator.viewModel.state.showSearchView },
            set: { coordinator.viewModel.send(.setPresentation(.searchView, $0)) }
        )) {
            SearchView(viewModel: coordinator.makeSearchViewModel())
        }
        .alert(
            coordinator.viewModel.state.alertTitle,
            isPresented: Binding(
                get: { coordinator.viewModel.state.showAlert },
                set: { coordinator.viewModel.send(.setAlert(isPresented: $0)) }
            )
        ) {
            alertButtons
        } message: {
            Text(coordinator.viewModel.state.alertMessage)
        }
        .toast(
            isPresented: Binding(
                get: { coordinator.viewModel.state.showToast },
                set: { coordinator.viewModel.send(.setToast(isPresented: $0)) }
            ),
            duration: 5,
            action: { coordinator.viewModel.send(.undoDeleteWebPage) }
        ) {
            Label(coordinator.viewModel.state.toastMessage, systemImage: "arrow.uturn.left")
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            coordinator.viewModel.send(.onAppear)
        }
        .overlay {
            if coordinator.viewModel.state.isAppending {
                LoadingView()
            }
        }
    }

    @ViewBuilder
    private var alertButtons: some View {
        switch coordinator.viewModel.state.alertType {
        case .webPageInput:
            TextField(
                "https://",
                text: Binding(
                    get: { coordinator.viewModel.state.webPageURLInput },
                    set: { coordinator.viewModel.send(.updateWebPageURLInput($0)) }
                )
            )
            .textInputAutocapitalization(.never)
            .keyboardType(.URL)
            Button(String(localized: "home_add")) {
                coordinator.viewModel.send(.addWebPage)
            }
            Button(String(localized: "common_cancel"), role: .cancel) {
                coordinator.viewModel.send(.setAlert(isPresented: false))
            }
        case .invalidURL, .error, .none:
            Button(String(localized: "common_close"), role: .cancel) {
                coordinator.viewModel.send(.setAlert(isPresented: false))
            }
        }
    }

    private var todoSection: some View {
        Section(content: {
            if coordinator.viewModel.state.isPreferencesLoading {
                LoadingView()
            } else {
                let preferences = coordinator.viewModel.state.preferences
                ForEach(preferences.filter { $0.isVisible }, id: \.id) { item in
                    todoCategoryRow(item)
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
                    coordinator.viewModel.send(.setPresentation(.reorderTodo, true))
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
            if coordinator.viewModel.state.isRecentTodosLoading {
                LoadingView()
            } else if coordinator.viewModel.state.recentTodos.isEmpty {
                HStack {
                    Spacer()
                    Text(String(localized: "home_recent_empty"))
                        .font(.callout)
                    Spacer()
                }
            } else {
                ForEach(coordinator.viewModel.state.recentTodos, id: \.id) { todo in
                    recentTodoRow(todo)
                }
            }
        } header: {
            HStack {
                Text(String(localized: "home_recent_title"))
                    .foregroundStyle(Color.primary)
                    .font(.title2.bold())
                Spacer()
            }
            .listRowInsets(EdgeInsets())
        }
    }

    private var webPageSection: some View {
        Section {
            let webPages = coordinator.viewModel.state.webPages.filter { !$0.isHidden }
            if coordinator.viewModel.state.isWebPageLoading {
                LoadingView()
                    .id(UUID()) //  id 부여를 통해 렌더링 강제
            } else if coordinator.viewModel.state.needsWebPageRefresh {
                Button {
                    coordinator.viewModel.send(.refreshWebPages)
                } label: {
                    HStack {
                        Spacer()
                        Text(String(localized: "home_web_refresh_required"))
                            .font(.callout)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            } else if webPages.isEmpty {
                HStack {
                    Spacer()
                    Text(String(localized: "home_web_empty"))
                        .font(.callout)
                    Spacer()
                }
            } else {
                ForEach(webPages, id: \.id) { page in
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
                coordinator.viewModel.send(.setPresentation(.contentPicker, true))
            } label: {
                Image(systemName: "plus")
            }
            .disabled(!coordinator.viewModel.state.isNetworkConnected)
        }
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                coordinator.viewModel.send(.setPresentation(.searchView, true))
            } label: {
                Image(systemName: "magnifyingglass")
            }
        }
    }

    @ViewBuilder
    private func todoCategoryRow(_ item: TodoCategoryItem) -> some View {
        if isCompactLayout {
            NavigationLink(value: HomeRoute.category(item)) {
                labelImage(
                    text: item.localizedName,
                    systemName: item.symbolName,
                    imageColor: item.color
                )
            }
        } else {
            Button {
                coordinator.router.replace(with: .category(item))
            } label: {
                labelImage(
                    text: item.localizedName,
                    systemName: item.symbolName,
                    imageColor: item.color
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func recentTodoRow(_ item: RecentTodoItem) -> some View {
        if isCompactLayout {
            NavigationLink(value: HomeRoute.todo(TodoIdItem(id: item.id))) {
                RecentTodoRow(todo: item)
            }
        } else {
            Button {
                coordinator.router.replace(with: .todo(TodoIdItem(id: item.id)))
            } label: {
                RecentTodoRow(todo: item)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func webResultRow(_ item: WebPageItem) -> some View {
        Group {
            if isCompactLayout {
                NavigationLink(value: HomeRoute.webPage(item)) {
                    WebItemRow(item: item, showsChevron: false)
                }
            } else {
                Button {
                    coordinator.router.replace(with: .webPage(item))
                } label: {
                    WebItemRow(item: item, showsChevron: false)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                coordinator.viewModel.send(.deleteWebPage(item))
            } label: {
                Label(String(localized: "common_delete"), systemImage: "trash")
            }
        }
    }

    private var contentPicker: some View {
        NavigationStack {
            List {
                Section {
                    if coordinator.viewModel.state.isPreferencesLoading {
                        LoadingView()
                    } else {
                        let preferences = coordinator.viewModel.state.preferences.filter(\.isVisible)
                        ForEach(preferences, id: \.id) { item in
                            Button {
                                DispatchQueue.main.async {
                                    coordinator.viewModel.send(.tapTodoCategory(item.category))
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
                            coordinator.viewModel.send(.setAlert(isPresented: true, type: .webPageInput))
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
            .navigationTitle(String(localized: "nav_home_content"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        coordinator.viewModel.send(.setPresentation(.contentPicker, false))
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
                .frame(width: labelWidth, height: labelWidth)
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
        .contentShape(.rect)
    }

}

enum HomeRoute: Hashable {
    case category(TodoCategoryItem)
    case todo(TodoIdItem)
    case webPage(WebPageItem)
}

private struct RecentTodoRow: View {
    @ScaledMetric(relativeTo: .largeTitle) private var labelWidth = CGFloat(34)
    let todo: RecentTodoItem

    var body: some View {
        let category = TodoCategoryItem(from: todo.category)
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(category.color)
                .frame(width: labelWidth, height: labelWidth)
                .overlay {
                    Image(systemName: category.symbolName)
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
                    Text("#\(todo.number)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.gray)
                        .fixedSize(horizontal: true, vertical: false)
                }

                HStack(spacing: 6) {
                    Text(category.localizedName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(category.color)

                    RelativeTimeText(date: todo.updatedAt)
                }

                if !todo.tags.isEmpty {
                    TagList(todo.tags, lineLimit: 1)
                }
            }
        }
    }
}
