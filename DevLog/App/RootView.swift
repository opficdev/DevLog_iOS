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

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            if let signIn = viewModel.state.signIn {
                if signIn {
                    MainView(viewModel: MainViewModel(
                        observeUnreadPushCountUseCase: container.resolve(ObserveUnreadPushCountUseCase.self)
                    ))
                } else {
                    LoginView(viewModel: LoginViewModel(
                        signInUseCase: container.resolve(SignInUseCase.self))
                    )
                }
            }
        }
        .preferredColorScheme(viewModel.state.theme.colorScheme)
        .onAppear { viewModel.send(.onAppear) }
        .alert(viewModel.state.alertTitle, isPresented: Binding(
            get: { viewModel.state.showAlert },
            set: { viewModel.send(.setAlert($0)) }
        )) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.state.alertMessage)
        }
        .sheet(item: $selectedRoute) { route in
            switch route {
            case .todoDetail(let todoId):
                NavigationStack {
                    TodoDetailView(viewModel: TodoDetailViewModel(
                        fetchUseCase: container.resolve(FetchTodoByIdUseCase.self),
                        fetchTodoIDsByNumbersUseCase: container.resolve(FetchTodoIDsByNumbersUseCase.self),
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
        .onReceive(PushNotificationRoute.shared.publisher) { route in
            selectedRoute = route
            PushNotificationRoute.shared.clear()
        }
    }
}
