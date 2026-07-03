//
//  TodayViewCoordinator.swift
//  Presentation
//
//  Created by opfic on 5/10/26.
//

import Foundation
import Core
import Domain
import PresentationShared

@MainActor
@Observable
final class TodayViewCoordinator {
    let store: StoreOf<TodayFeature>
    let router = NavigationRouter<TodayRoute>()

    init(container: DIContainer) {
        let fetchDisplayOptionsUseCase = container.resolve(FetchTodayDisplayOptionsUseCase.self)
        self.store = Store(
            initialState: TodayFeature.State(
                displayOptions: fetchDisplayOptionsUseCase.execute()
            )
        ) {
            TodayFeature()
        } withDependencies: {
            $0.todayFetchTodosUseCase = container.resolve(FetchTodosUseCase.self)
            $0.fetchTodoByIdUseCase = container.resolve(FetchTodoByIdUseCase.self)
            $0.upsertTodoUseCase = container.resolve(UpsertTodoUseCase.self)
            $0.updateTodayDisplayOptionsUseCase = container.resolve(UpdateTodayDisplayOptionsUseCase.self)
            $0.trackAnalyticsEventUseCase = container.resolve(TrackAnalyticsEventUseCase.self)
        }
    }

    func fetchData() {
        store.send(.fetchData)
    }
}
