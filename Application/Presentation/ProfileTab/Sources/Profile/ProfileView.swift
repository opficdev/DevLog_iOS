//
//  ProfileView.swift
//  ProfileTab
//
//  Created by opfic on 5/7/25.
//

import SwiftUI
import Core
import Domain
import PresentationShared

public struct ProfileView: View {
    @State private var settingsStore: StoreOf<SettingsFeature>
    @State private var store: StoreOf<ProfileFeature>
    @State private var path = [ProfileRoute]()
    private let isSelected: Bool
    private let windowEvent: TodoEditorWindowEvent

    public init(
        isSelected: Bool,
        windowEvent: TodoEditorWindowEvent
    ) {
        let store = Store(initialState: ProfileFeature.State()) {
            ProfileFeature()
        }
        let settingsStore = Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
        self._store = State(initialValue: store)
        self._settingsStore = State(initialValue: settingsStore)
        self.isSelected = isSelected
        self.windowEvent = windowEvent
    }

    public var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                    Section {
                        UserInfoCard(store: store, isSelected: isSelected)
                        ActivityCard(store: store) { todoId in
                            path.append(.activity(todoId))
                        }
                        GoalSummaryCard(
                            goals: store.developmentGoals,
                            isLoading: store.isDevelopmentGoalsLoading,
                            hasLoaded: store.hasDevelopmentGoalsLoaded,
                            hasLoadFailure: store.hasDevelopmentGoalsLoadFailure,
                            onRetry: { store.send(.retryDevelopmentGoals) }
                        )
                        RecentActivityCard(store: store) { todoId in
                            path.append(.recentTodo(todoId))
                        }
                    } header: {
                        titleBar
                            .toolbarBackground(Color.appBackground)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .refreshable { await store.send(.refresh).finish() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .background(Color.appBackground)
            .navigationDestination(for: ProfileRoute.self, destination: destinationView)
        }
        .onChange(of: isSelected, initial: true) { _, isSelected in
            if isSelected {
                store.send(.fetchData)
            }
        }
        .onAppear {
            store.send(.startObserving)
            settingsStore.send(.startObserving)
        }
        .prominentAlert(store, state: \.alert, action: \.alert)
        .sheet(
            isPresented: $store.showQuarterPicker.activePresentation(when: isSelected)
        ) { QuarterPickerSheet(store: store) }
        .overlay {
            if store.isLoading {
                LoadingView()
            }
        }
    }

    private var titleBar: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("nav_profile", bundle: PresentationResources.bundle)
                    .font(.largeTitle.bold())
                Spacer()
                Button {
                    path.append(.settings)
                } label: {
                    Image(systemName: "gearshape")
                }
                .topBarButtonStyle()
            }
        }
        .padding(.bottom, 8)
        .background(Color.appBackground)
    }

    @ViewBuilder
    private func destinationView(_ route: ProfileRoute) -> some View {
        switch route {
        case .settings:
            SettingsView(store: settingsStore) { path.append($0) }
        case .activity(let todoId):
            TodoDetailView(store: Store(
                initialState: TodoDetailFeature.State(todoId: todoId, showEditButton: false)
            ) {
                TodoDetailFeature()
            })
        case .recentTodo(let todoId):
            TodoDetailView(store: Store(
                initialState: TodoDetailFeature.State(todoId: todoId, showEditButton: true)
            ) {
                TodoDetailFeature()
            }, windowEvent: windowEvent)
        case .theme:
            ThemeView(theme: $settingsStore.theme)
        case .pushNotification:
            PushNotificationSettingsView(store: Store(
                initialState: PushNotificationSettingsFeature.State()
            ) {
                PushNotificationSettingsFeature()
            })
        case .account:
            AccountView(store: Store(initialState: AccountFeature.State()) {
                AccountFeature()
            })
        }
    }
}

enum ProfileRoute: Hashable {
    case settings
    case activity(String)
    case recentTodo(String)
    case theme
    case pushNotification
    case account
}
