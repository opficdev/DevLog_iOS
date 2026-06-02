//
//  MainViewCoordinator.swift
//  DevLogPresentation
//
//  Created by opfic on 5/9/26.
//

import Foundation
import DevLogCore
import DevLogDomain

@MainActor
@Observable
final class MainViewCoordinator {
    let viewModel: MainViewModel

    init(container: DIContainer) {
        self.viewModel = MainViewModel(
            trackAnalyticsEventUseCase: container.resolve(TrackAnalyticsEventUseCase.self),
            unreadPushCountUseCase: container.resolve(ObserveUnreadPushCountUseCase.self)
        )
    }
}
