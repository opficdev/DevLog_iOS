//
//  TodayViewCoordinator.swift
//  DevLogPresentation
//
//  Created by opfic on 5/10/26.
//

import Foundation
import DevLogCore
import DevLogDomain

@MainActor
@Observable
public final class TodayViewCoordinator {
    public let viewModel: TodayViewModel
    public let router = NavigationRouter<TodayRoute>()

    public init(container: DIContainer) {
        self.viewModel = TodayViewModel(
            fetchTodosUseCase: container.resolve(FetchTodosUseCase.self),
            fetchTodoByIdUseCase: container.resolve(FetchTodoByIdUseCase.self),
            upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
            fetchTodayDisplayOptionsUseCase: container.resolve(FetchTodayDisplayOptionsUseCase.self),
            updateTodayDisplayOptionsUseCase: container.resolve(UpdateTodayDisplayOptionsUseCase.self),
            trackAnalyticsEventUseCase: container.resolve(TrackAnalyticsEventUseCase.self)
        )
    }

    public func fetchData() {
        viewModel.send(.fetchData)
    }
}
