//
//  RootView.swift
//  DevLogPresentation
//
//  Created by opfic on 5/2/25.
//

import SwiftUI
import Combine
import DevLogCore
import DevLogDomain

public struct RootView: View {
    @Environment(\.diContainer) var container: DIContainer
    @State var viewModel: RootViewModel
    @State private var selectedRoute: Route?
    @State private var selectedMainTab: MainTab?
    private let widgetURLTab: (URL) -> MainTab?
    private let pushNotificationTodoIdPublisher: AnyPublisher<String, Never>
    private let clearPushNotificationRoute: () -> Void

    public init(
        sessionUseCase: ObserveAuthSessionUseCase,
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase,
        systemThemeUseCase: ObserveSystemThemeUseCase,
        widgetURLTab: @escaping (URL) -> MainTab?,
        pushNotificationTodoIdPublisher: AnyPublisher<String, Never>,
        clearPushNotificationRoute: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: RootViewModel(
            sessionUseCase: sessionUseCase,
            networkConnectivityUseCase: networkConnectivityUseCase,
            systemThemeUseCase: systemThemeUseCase
        ))
        self.widgetURLTab = widgetURLTab
        self.pushNotificationTodoIdPublisher = pushNotificationTodoIdPublisher
        self.clearPushNotificationRoute = clearPushNotificationRoute
    }

    public var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            if let signIn = viewModel.state.signIn {
                if signIn {
                    MainView(
                        container: container,
                        selectedTab: $selectedMainTab
                    )
                } else {
                    LoginView(viewModel: LoginViewModel(
                        signInUseCase: container.resolve(SignInUseCase.self))
                    )
                }
            }
        }
        .preferredColorScheme(viewModel.state.theme.colorScheme)
        .onAppear { viewModel.send(.onAppear) }
        .onChange(of: viewModel.state.signIn) { _, value in
            guard let value else { return }
            if value {
                selectedMainTab = .home
            } else {
                selectedMainTab = nil
            }
        }
        .onOpenURL { url in
            guard let mainTab = widgetURLTab(url) else { return }
            switch viewModel.state.signIn {
            case .some(false):
                break
            case .some(true):
                selectedMainTab = mainTab
            case .none:
                break
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
        .sheet(item: $selectedRoute) { route in
            switch route {
            case .todoDetail(let todoId):
                NavigationStack {
                    TodoDetailView(viewModel: TodoDetailViewModel(
                        fetchTodoUseCase: container.resolve(FetchTodoByIdUseCase.self),
                        fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
                        upsertUseCase: container.resolve(UpsertTodoUseCase.self),
                        todoId: todoId,
                        showEditButton: false
                    ))
                    .toolbar {
                        ToolbarLeadingButton {
                            selectedRoute = nil
                        }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .presentationDragIndicator(.visible)
            }
        }
        .onReceive(pushNotificationTodoIdPublisher) { todoId in
            selectedRoute = .todoDetail(todoId)
            clearPushNotificationRoute()
        }
    }
}

private enum Route: Equatable, Identifiable {
    case todoDetail(String)

    var id: String {
        switch self {
        case .todoDetail(let todoId):
            return "todo:\(todoId)"
        }
    }
}
