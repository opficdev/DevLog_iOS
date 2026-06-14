//
//  HomeView.swift
//  DevLogPresentation
//
//  Created by opfic on 5/7/25.
//

import SwiftUI
import ComposableArchitecture
import DevLogDomain

struct HomeView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.isiOSAppOnMac) private var isiOSAppOnMac
    @ScaledMetric(relativeTo: .largeTitle) private var labelWidth = CGFloat(34)
    @Bindable var store: StoreOf<HomeFeature>
    let coordinator: HomeViewCoordinator
    let isCompactLayout: Bool

    init(
        coordinator: HomeViewCoordinator,
        isCompactLayout: Bool
    ) {
        self.coordinator = coordinator
        self.isCompactLayout = isCompactLayout
        self.store = coordinator.store
    }

    var body: some View {
        List {
            todoSection
            recentTodoSection
            webPageSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "nav_home"))
        .toolbar { toolbar }
        .sheet(item: $store.scope(state: \.sheet, action: \.sheet)) { sheetStore in
            switch sheetStore.state {
            case .reorderTodo:
                CategoryManageView(
                    preferences: store.preferences,
                    onDismiss: { array in
                        store.send(.sheet(.dismiss))
                        store.send(.orderTodoCategory(array), animation: .default)
                    }
                )
            case .contentPicker:
                contentPicker
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { store.showTodoEditor },
            set: { store.send(.setPresentation(.todoEditor, $0)) }
        )) {
            if let selectedCategory = store.selectedTodoCategory {
                TodoEditorView(
                    store: coordinator.makeTodoEditorStore(category: selectedCategory),
                    onCreateSuccess: {
                        store.send(.setPresentation(.todoEditor, false))
                        store.send(.fetchData)
                    }
                )
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { store.showSearchView },
            set: { store.send(.setPresentation(.searchView, $0)) }
        )) {
            SearchView(store: coordinator.makeSearchStore())
        }
        .alert(
            store.alertTitle,
            isPresented: Binding(
                get: { store.showAlert },
                set: { store.send(.setAlert(isPresented: $0)) }
            )
        ) {
            alertButtons
        } message: {
            Text(store.alertMessage)
        }
        .overlay {
            if store.isAppending {
                LoadingView()
            }
        }
    }

    @ViewBuilder
    private var alertButtons: some View {
        switch store.alertType {
        case .webPageInput:
            TextField(
                "https://",
                text: Binding(
                    get: { store.webPageURLInput },
                    set: { store.send(.updateWebPageURLInput($0)) }
                )
            )
            .textInputAutocapitalization(.never)
            .keyboardType(.URL)
            Button(String(localized: "home_add")) {
                store.send(.addWebPage)
            }
            Button(String(localized: "common_cancel"), role: .cancel) {
                store.send(.setAlert(isPresented: false))
            }
        case .invalidURL, .error, .none:
            Button(String(localized: "common_close"), role: .cancel) {
                store.send(.setAlert(isPresented: false))
            }
        }
    }

    private var todoSection: some View {
        Section(content: {
            if store.isPreferencesLoading {
                LoadingView()
            } else {
                let preferences = store.preferences
                ForEach(preferences.filter { $0.isVisible }, id: \.id) { item in
                    todoCategoryRow(item)
                        .listRowInsets((EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)))
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
                    store.send(.setSheet(.reorderTodo))
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
            if store.isRecentTodosLoading {
                LoadingView()
            } else if store.recentTodos.isEmpty {
                HStack {
                    Spacer()
                    Text(String(localized: "home_recent_empty"))
                        .font(.callout)
                    Spacer()
                }
            } else {
                ForEach(store.recentTodos, id: \.id) { todo in
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
            let webPages = store.webPages.filter { !$0.isHidden }
            if store.isWebPageLoading {
                LoadingView()
                    .id(UUID()) //  id 부여를 통해 렌더링 강제
            } else if store.needsWebPageRefresh {
                Button {
                    store.send(.refreshWebPages)
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
                store.send(.setSheet(.contentPicker))
            } label: {
                Image(systemName: "plus")
            }
            .disabled(!store.isNetworkConnected)
        }
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                store.send(.setPresentation(.searchView, true))
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
                    .contentShape(.rect)
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
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.send(.deleteWebPage(item))
                presentDeleteWebPageToast(item.url.absoluteString)
            } label: {
                Label(String(localized: "common_delete"), systemImage: "trash")
            }
        }
    }

    private var contentPicker: some View {
        NavigationStack {
            List {
                Section {
                    if store.isPreferencesLoading {
                        LoadingView()
                    } else {
                        let preferences = store.preferences.filter(\.isVisible)
                        ForEach(preferences, id: \.id) { item in
                            Button {
                                DispatchQueue.main.async {
                                    openTodoEditor(for: item.category)
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
                            store.send(.setAlert(isPresented: true, type: .webPageInput))
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
                        store.send(.sheet(.presented(.tapCloseButton)))
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
        .contentShape(.rect)
    }

    private func openTodoEditor(for todoCategory: TodoCategory) {
        if isiOSAppOnMac {
            store.send(.setPresentation(.contentPicker, false))
            openWindow(
                id: TodoEditorWindowValue.sceneId,
                value: TodoEditorWindowValue(todoCategory: todoCategory, source: .home)
            )
        } else {
            store.send(.tapTodoCategory(todoCategory))
        }
    }

    private func presentDeleteWebPageToast(_ urlString: String) {
        ToastPresenter.present(
            message: String(localized: "common_undo"),
            systemImage: "arrow.uturn.left",
            duration: 5,
            font: .caption,
            multilineTextAlignment: .center,
            action: {
                store.send(.undoDeleteWebPage)
            },
            onDismiss: {
                store.send(.finishDeleteWebPageToast(urlString))
            }
        )
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
