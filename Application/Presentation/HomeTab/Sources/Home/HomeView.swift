//
//  HomeView.swift
//  HomeTab
//
//  Created by opfic on 5/7/25.
//

import SwiftUI
import Combine
import Development
import Domain
import PresentationShared

public struct HomeView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.openWindow) private var openWindow
    @Environment(\.isiOSAppOnMac) private var isiOSAppOnMac
    @ScaledMetric(relativeTo: .largeTitle) private var labelWidth = CGFloat(34)
    @ScaledMetric(relativeTo: .title2) private var categoryIconSize = CGFloat(64)
    @State private var path = [HomeRoute]()
    @State private var goalPresentation: GoalPresentation?
    @State private var searchStore: StoreOf<SearchFeature>
    @State private var store: StoreOf<HomeFeature>
    private let isSelected: Bool
    private let windowEvent: TodoEditorWindowEvent

    public init(
        isSelected: Bool,
        windowEvent: TodoEditorWindowEvent
    ) {
        @Dependency(\.homeFetchRecentSearchQueriesUseCase) var fetchRecentSearchQueriesUseCase
        self._store = State(initialValue: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        })
        self._searchStore = State(initialValue: Store(
            initialState: SearchFeature.State(
                recentQueries: fetchRecentSearchQueriesUseCase.execute()
            )
        ) {
            SearchFeature()
        })
        self.isSelected = isSelected
        self.windowEvent = windowEvent
    }

    public var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    DevelopmentSummaryCard(
                        items: store.developmentGoalItems,
                        isLoading: store.isDevelopmentGoalsLoading,
                        hasLoaded: store.hasDevelopmentGoalsLoaded,
                        hasLoadFailure: store.hasDevelopmentGoalsLoadFailure
                    )
                    todoSection
                    DevelopmentGoalSection(
                        items: store.developmentGoalItems,
                        isLoading: store.isDevelopmentGoalsLoading,
                        hasLoaded: store.hasDevelopmentGoalsLoaded,
                        hasLoadFailure: store.hasDevelopmentGoalsLoadFailure,
                        onCreate: { goalPresentation = .create },
                        onSelect: { goalPresentation = .detail($0.id) },
                        onRetry: { store.send(.view(.fetchData)) }
                    )
                }
                .padding(.horizontal, 16)
            }
            .safeAreaInset(edge: .top, spacing: 0) { topBar }
            .background(Color.appBackground)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationDestination(for: HomeRoute.self, destination: destinationView)
        }
        .onAppear { store.send(.view(.startObserving)) }
        .onChange(of: isSelected, initial: true) { _, isSelected in
            if isSelected {
                store.send(.view(.fetchData))
            }
        }
        .onReceive(windowEvent.submits) { submit in
            guard case .create(let value) = submit,
                  value.matchesCreate(source: .home) else { return }
            store.send(.view(.todoEditorCreated))
        }
        .prominentAlert(store, state: \.alert, action: \.alert)
        .sheet(
            item: $store.scope(state: \.sheet, action: \.sheet)
                .activePresentation(when: isSelected),
            content: sheetContent
        )
        .sheet(item: $goalPresentation, onDismiss: refreshDevelopmentGoals) { presentation in
            switch presentation {
            case .create:
                GoalCreateView()
            case .detail(let goalID):
                GoalDetailView(goalId: goalID)
            }
        }
        .fullScreenCover(
            item: $store.scope(state: \.fullScreenCover, action: \.fullScreenCover)
                .activePresentation(when: isSelected),
            content: coverContent
        )
    }

    @ViewBuilder
    private var topBar: some View {
        HStack(spacing: 12) {
            Text("DevLog")
                .font(.largeTitle.weight(.bold))
            Spacer()
            if #available(iOS 26.0, *) {
                Button {
                    store.send(.store(.setPresentation(.searchView, true)))
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .topBarButtonStyle()
            } else {
                Button {
                    store.send(.store(.setPresentation(.searchView, true)))
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title3.weight(.semibold))
                        .frame(width: 28, height: 28)
                }
                .adaptiveButtonStyle(
                    shape: .circle,
                    color: .surface,
                    glassEffect: .enabled
                )
            }
            if #available(iOS 26.0, *) {
                Button {
                    store.send(.store(.setPresentation(.contentPicker, true)))
                } label: {
                    Image(systemName: "plus")
                }
                .topBarButtonStyle()
                .disabled(!store.isNetworkConnected)
            } else {
                Button {
                    store.send(.store(.setPresentation(.contentPicker, true)))
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .frame(width: 28, height: 28)
                }
                .adaptiveButtonStyle(
                    shape: .circle,
                    color: .surface,
                    glassEffect: .enabled
                )
                .disabled(!store.isNetworkConnected)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(Color.appBackground)
        .toolbarBackground(Color.appBackground)
    }

    @ViewBuilder
    private var todoSection: some View {
        let visibleCategoryCount = store.preferences.filter(\.isVisible).count
        let collapsedCategoryCount = min(visibleCategoryCount, 8)
        let columnCount = dynamicTypeSize.isAccessibilitySize ? 2 : 4
        let showsExpansionButton = 8 < visibleCategoryCount
            || 0 < collapsedCategoryCount && collapsedCategoryCount.isMultiple(of: columnCount)

        VStack(alignment: .leading, spacing: 0) {
            if store.isPreferencesLoading {
                LoadingView()
                    .frame(maxWidth: .infinity)
            } else {
                todoCategoryGrid
            }

            if !store.isPreferencesLoading, showsExpansionButton {
                HStack {
                    Spacer()
                    Button {
                        store.send(
                            .view(.tapTodoCategoryExpansionButton),
                            animation: .easeInOut(duration: 0.2)
                        )
                    } label: {
                        Image(systemName: store.isTodoCategoryExpanded ? "chevron.up" : "chevron.down")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.textTertiary)
                            .frame(width: 32, height: 32)
                    }
                    Spacer()
                }
            }
        }
        .padding(.bottom, 12)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 28))
    }

    @ViewBuilder
    private var todoCategoryGrid: some View {
        let preferences = store.preferences.filter(\.isVisible)
        let visiblePreferences = store.isTodoCategoryExpanded
            ? preferences
            : Array(preferences.prefix(8))
        let columnCount = dynamicTypeSize.isAccessibilitySize ? 2 : 4
        let hasAvailableSlot = visiblePreferences.isEmpty
            || !visiblePreferences.count.isMultiple(of: columnCount)

        TodoCategoryGridLayout(
            columnCount: columnCount,
            itemWidth: categoryIconSize
        ) {
            ForEach(visiblePreferences) { item in
                todoCategoryRow(item)
            }
            if store.isTodoCategoryExpanded || hasAvailableSlot {
                editTodoCategoryButton
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var editTodoCategoryButton: some View {
        Button {
            store.send(.view(.tapManageTodoCategory))
        } label: {
            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        Color.textTertiary,
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )
                    .frame(width: categoryIconSize, height: categoryIconSize)
                    .overlay {
                        Image(systemName: "square.grid.2x2")
                            .font(.title2.bold())
                            .foregroundStyle(Color.textTertiary)
                    }
                Text("todo_edit", bundle: PresentationResources.bundle)
                    .font(.subheadline)
                    .foregroundStyle(Color.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func sheetContent(_ sheetStore: Store<HomeFeature.SheetState, HomeFeature.Sheet>) -> some View {
        if case .contentPicker = sheetStore.state {
            NavigationStack {
                List {
                    Section {
                        if store.isPreferencesLoading {
                            LoadingView()
                        } else {
                            let preferences = store.preferences.filter(\.isVisible)
                            ForEach(preferences, id: \.id) { item in
                                Button {
                                    openTodoEditor(for: item.category)
                                } label: {
                                    labelImage(
                                        text: item.localizedName,
                                        systemName: item.symbolName,
                                        imageColor: item.color
                                    )
                                }
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            }
                        }
                    } header: {
                        Text("TODO", bundle: PresentationResources.bundle)
                            .foregroundStyle(Color(.label))
                    }

                }
                .navigationTitle(Text("TODO"))
                .navigationBarTitleDisplayMode(.inline)  //  설정 안하면 섹션 위에 내비게이션 large 만큼 영역 먹음
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
        } else if let store = sheetStore.scope(state: \.categoryManageState, action: \.categoryManage) {
            CategoryManageView(store: store)
        }
    }

    @ViewBuilder
    private func coverContent(
        _ coverStore: Store<HomeFeature.FullScreenCoverState, HomeFeature.FullScreenCover>
    ) -> some View {
        switch coverStore.destination {
        case .todoEditor:
            if let todoEditorStore = coverStore.scope(state: \.todoEditor, action: \.todoEditor) {
                TodoEditorView(store: todoEditorStore)
            }
        case .search:
            SearchView(store: searchStore)
        }
    }

    @ViewBuilder
    private func destinationView(_ route: HomeRoute) -> some View {
        switch route {
        case .category(let item):
            TodoListView(
                store: Store(initialState: TodoListFeature.State(category: item.todoCategory)) {
                    TodoListFeature()
                },
                windowEvent: windowEvent,
                onSelectTodo: { path.append(.todo(TodoIdItem(id: $0))) }
            )
            .id(item.id)
        case .todo(let item):
            TodoDetailView(
                store: Store(
                    initialState: TodoDetailFeature.State(todoId: item.id, showEditButton: true)
                ) {
                    TodoDetailFeature()
                },
                windowEvent: windowEvent
            )
            .id(item.id)
        }
    }

    private func todoCategoryRow(_ item: TodoCategoryItem) -> some View {
        NavigationLink(value: HomeRoute.category(item)) {
            VStack(spacing: 10) {
                Image(systemName: item.symbolName)
                    .font(.title2.bold())
                    .frame(width: categoryIconSize, height: categoryIconSize)
                    .iconStyle(
                        color: item.color,
                        in: RoundedRectangle(cornerRadius: 20)
                    )
                Text(item.localizedName)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
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
            store.send(.store(.setPresentation(.contentPicker, false)))
            openWindow(
                id: TodoEditorWindowValue.sceneId,
                value: TodoEditorWindowValue(todoCategory: todoCategory, source: .home)
            )
        } else {
            store.send(.view(.tapTodoCategory(todoCategory)))
        }
    }
    private func refreshDevelopmentGoals() {
        store.send(.view(.fetchData))
    }
}

public enum HomeRoute: Hashable {
    case category(TodoCategoryItem)
    case todo(TodoIdItem)
}
