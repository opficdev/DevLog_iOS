//
//  TodayViewCoordinator.swift
//  DevLog
//
//  Created by opfic on 5/10/26.
//

import Foundation

@MainActor
@Observable
final class TodayViewCoordinator {
    let viewModel: TodayViewModel
    let router = NavigationRouter<TodayRoute>()

    init(container: DIContainer) {
        self.viewModel = TodayViewModel(
            fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
            fetchTodoByIdUseCase: container.resolve(FetchTodoByIdUseCase.self),
            upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
            fetchTodayDisplayOptionsUseCase: container.resolve(FetchTodayDisplayOptionsUseCase.self),
            updateTodayDisplayOptionsUseCase: container.resolve(UpdateTodayDisplayOptionsUseCase.self)
        )
    }
}
