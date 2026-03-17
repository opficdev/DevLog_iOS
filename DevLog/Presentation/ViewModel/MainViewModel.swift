//
//  MainViewModel.swift
//  DevLog
//
//  Created by opfic on 3/17/26.
//

import Foundation
import Combine
import UserNotifications

@Observable
final class MainViewModel: Store {
    struct State: Equatable {
        var unreadPushCount = 0
        var showAlert = false
        var alertTitle = ""
        var alertMessage = ""
    }

    enum Action {
        case setUnreadPushCount(Int)
        case setAlert(Bool)
    }

    enum SideEffect {
        case updateBadgeCount(Int)
    }

    private(set) var state = State()
    private var cancellables = Set<AnyCancellable>()
    private let observeUnreadPushCountUseCase: ObserveUnreadPushCountUseCase

    init(
        observeUnreadPushCountUseCase: ObserveUnreadPushCountUseCase
    ) {
        self.observeUnreadPushCountUseCase = observeUnreadPushCountUseCase
        observeUnreadPushCount()
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var sideEffects: [SideEffect] = []

        switch action {
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
        state.alertTitle = "오류"
        state.alertMessage = "알림 배지를 불러오는 중 문제가 발생했습니다."
        state.showAlert = isPresented
    }

    func observeUnreadPushCount() {
        do {
            try observeUnreadPushCountUseCase.execute()
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        guard let self else { return }
                        if case .failure = completion {
                            self.send(.setAlert(true))
                        }
                    },
                    receiveValue: { [weak self] count in
                        self?.send(.setUnreadPushCount(count))
                    }
                )
                .store(in: &cancellables)
        } catch {
            send(.setAlert(true))
        }
    }

    func updateBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count) { _ in }
    }
}
