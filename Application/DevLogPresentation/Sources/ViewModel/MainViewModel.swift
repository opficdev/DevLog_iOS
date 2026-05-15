//
//  MainViewModel.swift
//  DevLog
//
//  Created by opfic on 3/17/26.
//

import Foundation
import Combine
import UserNotifications
import DevLogDomain
import DevLogData

@Observable
final class MainViewModel: Store {
    struct State: Equatable {
        var unreadPushCount = 0
        var showAlert = false
        var alertTitle = ""
        var alertMessage = ""
    }

    enum Action {
        case onAppear
        case setUnreadPushCount(Int)
        case setAlert(Bool)
    }

    enum SideEffect {
        case observeUnreadPushCount
        case updateBadgeCount(Int)
    }

    private(set) var state = State()
    private let logger = Logger(category: "MainViewModel")
    private var cancellables = Set<AnyCancellable>()
    private var isObservingUnreadPushCount = false
    private let unreadPushCountUseCase: ObserveUnreadPushCountUseCase

    init(
        unreadPushCountUseCase: ObserveUnreadPushCountUseCase
    ) {
        self.unreadPushCountUseCase = unreadPushCountUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var sideEffects: [SideEffect] = []

        switch action {
        case .onAppear:
            if !isObservingUnreadPushCount {
                isObservingUnreadPushCount = true
                sideEffects = [.observeUnreadPushCount]
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

    func run(_ effect: SideEffect) {
        switch effect {
        case .observeUnreadPushCount:
            observeUnreadPushCount()
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
}
