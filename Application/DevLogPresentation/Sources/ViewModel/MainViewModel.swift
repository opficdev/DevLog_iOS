//
//  MainViewModel.swift
//  DevLogPresentation
//
//  Created by opfic on 3/17/26.
//

import Foundation
import Combine
import UserNotifications
import DevLogDomain
import DevLogCore

@Observable
public final class MainViewModel: Store {
    public struct State: Equatable {
        public var unreadPushCount = 0
        public var showAlert = false
        public var alertTitle = ""
        public var alertMessage = ""
    }

    public enum Action {
        case onAppear
        case selectedTabChanged(MainTab)
        case setUnreadPushCount(Int)
        case setAlert(Bool)
    }

    public enum SideEffect {
        case observeUnreadPushCount
        case trackScreenView(MainTab)
        case updateBadgeCount(Int)
    }

    public private(set) var state = State()
    private let logger = Logger(category: "MainViewModel")
    private var cancellables = Set<AnyCancellable>()
    private var isObservingUnreadPushCount = false
    private let trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase
    private let unreadPushCountUseCase: ObserveUnreadPushCountUseCase

    public init(
        trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase,
        unreadPushCountUseCase: ObserveUnreadPushCountUseCase
    ) {
        self.trackAnalyticsEventUseCase = trackAnalyticsEventUseCase
        self.unreadPushCountUseCase = unreadPushCountUseCase
    }

    public func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var sideEffects: [SideEffect] = []

        switch action {
        case .onAppear:
            if !isObservingUnreadPushCount {
                isObservingUnreadPushCount = true
                sideEffects = [.observeUnreadPushCount]
            }
        case .selectedTabChanged(let tab):
            if tab.analyticsScreenName != nil {
                sideEffects = [.trackScreenView(tab)]
            }
        case .setUnreadPushCount(let count):
            state.unreadPushCount = count
            sideEffects = [.updateBadgeCount(count)]
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        }

        if self.state != state { self.state = state }
        return sideEffects
    }

    public func run(_ effect: SideEffect) {
        switch effect {
        case .observeUnreadPushCount:
            observeUnreadPushCount()
        case .trackScreenView(let tab):
            trackScreenView(tab)
        case .updateBadgeCount(let count):
            updateBadgeCount(count)
        }
    }
}

private extension MainViewModel {
    func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = String(localized: "common_error_title")
        state.alertMessage = String(localized: "main_alert_badge_error_message")
        state.showAlert = isPresented
    }

    func observeUnreadPushCount() {
        do {
            try unreadPushCountUseCase.observe()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        guard let self else { return }
                        if case .failure(let error) = completion {
                            logger.error("Failed to observe unread push count", error: error)
                            self.send(.setAlert(true))
                        }
                    },
                    receiveValue: { [weak self] count in
                        self?.send(.setUnreadPushCount(count))
                    }
                )
                .store(in: &cancellables)
        } catch {
            logger.error("Failed to start observing unread push count", error: error)
            send(.setAlert(true))
        }
    }

    func updateBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count) { [weak self] error in
            if let error {
                Task { @MainActor in
                    self?.logger.error("Failed to update application badge count", error: error)
                }
            }
        }
    }

    func trackScreenView(_ tab: MainTab) {
        guard let screenName = tab.analyticsScreenName else { return }
        trackAnalyticsEventUseCase.execute(.screenView(screenName))
    }
}

private extension MainTab {
    var analyticsScreenName: String? {
        switch self {
        case .home:
            return "home"
        case .today:
            return "today"
        case .notification:
            return nil
        case .profile:
            return "profile"
        }
    }
}
