//
//  RootView.swift
//  DevLog
//
//  Created by opfic on 5/2/25.
//

import SwiftUI
import DevLogPresentation
import DevLogUI
import Combine

struct RootView: View {
    @State private var dependencies: RootViewDependencies
    @State private var selectedRoute: Route?
    @State private var selectedMainTab: MainTab?
    private let widgetURLTab: (URL) -> MainTab?
    private let windowEvent: TodoEditorWindowEvent
    private let pushNotificationTodoIdPublisher: AnyPublisher<String, Never>
    private let clearPushNotificationRoute: () -> Void

    init(
        dependencies: RootViewDependencies,
        widgetURLTab: @escaping (URL) -> MainTab?,
        windowEvent: TodoEditorWindowEvent,
        pushNotificationTodoIdPublisher: AnyPublisher<String, Never>,
        clearPushNotificationRoute: @escaping () -> Void
    ) {
        self._dependencies = State(initialValue: dependencies)
        self.widgetURLTab = widgetURLTab
        self.windowEvent = windowEvent
        self.pushNotificationTodoIdPublisher = pushNotificationTodoIdPublisher
        self.clearPushNotificationRoute = clearPushNotificationRoute
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            if let signIn = dependencies.viewModel.state.signIn {
                if signIn {
                    MainView(
                        dependencies: dependencies.mainViewDependencies,
                        windowEvent: windowEvent,
                        selectedTab: $selectedMainTab
                    )
                } else {
                    LoginView(viewModel: dependencies.makeLoginViewModel())
                }
            }
        }
        .preferredColorScheme(dependencies.viewModel.state.theme.colorScheme)
        .onAppear { dependencies.viewModel.send(.onAppear) }
        .onChange(of: dependencies.viewModel.state.signIn) { _, value in
            guard let value else { return }
            if value {
                selectedMainTab = .home
            } else {
                selectedMainTab = nil
            }
        }
        .onOpenURL { url in
            guard let mainTab = widgetURLTab(url) else { return }
            switch dependencies.viewModel.state.signIn {
            case .some(false):
                break
            case .some(true):
                selectedMainTab = mainTab
            case .none:
                break
            }
        }
        .alert(dependencies.viewModel.state.alertTitle, isPresented: Binding(
            get: { dependencies.viewModel.state.showAlert },
            set: { dependencies.viewModel.send(.setAlert($0)) }
        )) {
            Button(String(localized: "common_close"), role: .cancel) { }
        } message: {
            Text(dependencies.viewModel.state.alertMessage)
        }
        .sheet(item: $selectedRoute) { route in
            switch route {
            case .todoDetail(let todoId):
                NavigationStack {
                    TodoDetailView(
                        viewModel: dependencies.makeTodoDetailViewModel(todoId),
                        todoViewModelFactory: dependencies.mainViewDependencies.todoViewModelFactory
                    )
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
