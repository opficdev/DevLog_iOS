//
//  MainViewCoordinator.swift
//  DevLogPresentation
//
//  Created by opfic on 5/9/26.
//

import Foundation
import ComposableArchitecture
import DevLogCore
import DevLogDomain

@MainActor
@Observable
final class MainViewCoordinator {
    let store: StoreOf<MainFeature>

    init(container: DIContainer) {
        self.store = Store(initialState: MainFeature.State()) {
            MainFeature()
        } withDependencies: {
            $0.observeUnreadPushCountUseCase = container.resolve(ObserveUnreadPushCountUseCase.self)
            $0.trackAnalyticsEventUseCase = container.resolve(TrackAnalyticsEventUseCase.self)
        }
    }
}
