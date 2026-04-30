//
//  RootView.swift
//  SwiftUI_DevLog
//
//  Created by opfic on 5/2/25.
//

import SwiftUI

struct RootView: View {
    @Environment(\.diContainer) var container: DIContainer
    @State var viewModel: RootViewModel
    @State private var selectedRoute: AppRoute?
    @State private var selectedMainTab = MainTab.home

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            if let signIn = viewModel.state.signIn {
                if signIn {
                    MainView(
                        viewModel: MainViewModel(
                            unreadPushCountUseCase: container.resolve(ObserveUnreadPushCountUseCase.self)
                        ),
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
            guard value == false else { return }
            selectedMainTab = .home
        }
        .onOpenURL { url in
            guard let mainTab = MainTab(widgetURL: url) else { return }
            switch viewModel.state.signIn {
            case .some(false):
                selectedMainTab = .home
            case .some(true), .none:
                selectedMainTab = mainTab
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
        .onReceive(PushNotificationRoute.shared.observe()) { route in
            selectedRoute = route
            PushNotificationRoute.shared.clear()
        }
    }
}
