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
public final class MainViewCoordinator {
    public let viewModel: MainViewModel

    public init(container: DIContainer) {
        self.viewModel = MainViewModel(
            trackAnalyticsEventUseCase: container.resolve(TrackAnalyticsEventUseCase.self),
            unreadPushCountUseCase: container.resolve(ObserveUnreadPushCountUseCase.self)
        )
    }
}
