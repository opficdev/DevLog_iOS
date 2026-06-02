//
//  RootViewDependencies.swift
//  DevLogPresentation
//
//  Created by opfic on 6/2/26.
//

import DevLogCore
import DevLogDomain

@MainActor
public struct RootViewDependencies {
    public let viewModel: RootViewModel
    public let mainViewDependencies: MainViewDependencies
    public let makeLoginViewModel: () -> LoginViewModel
    public let makeTodoDetailViewModel: (String) -> TodoDetailViewModel

    public init(container: DIContainer) {
        self.viewModel = RootViewModel(
            sessionUseCase: container.resolve(ObserveAuthSessionUseCase.self),
            networkConnectivityUseCase: container.resolve(ObserveNetworkConnectivityUseCase.self),
            systemThemeUseCase: container.resolve(ObserveSystemThemeUseCase.self),
            trackAnalyticsEventUseCase: container.resolve(TrackAnalyticsEventUseCase.self)
        )
        self.mainViewDependencies = MainViewDependencies(container: container)
        self.makeLoginViewModel = {
            LoginViewModel(signInUseCase: container.resolve(SignInUseCase.self))
        }
        self.makeTodoDetailViewModel = { todoId in
            TodoDetailViewModel(
                fetchTodoUseCase: container.resolve(FetchTodoByIdUseCase.self),
                fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
                todoId: todoId,
                showEditButton: false
            )
        }
    }
}
