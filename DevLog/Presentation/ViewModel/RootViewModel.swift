//
//  RootViewModel.swift
//  DevLog
//
//  Created by AI on 2/12/26.
//

import Foundation
import Combine
import UserNotifications

@Observable
final class RootViewModel: Store {
    struct State: Equatable {
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
        var isNetworkConnected: Bool = true
        var signIn: Bool?
        var theme: SystemTheme = .automatic
    }
    
    enum Action {
        case onAppear
        case setAlert(Bool)
        case networkStatusChanged(Bool)
        case setTheme(SystemTheme)
        case didLogined(Bool)
    }

    enum SideEffect {
        case clearApplicationBadgeCount
    }

    private(set) var state: State
    private let connectivityProvider = NWPathConnectivityProvider()
    private var cancellables = Set<AnyCancellable>()
    private let sessionUseCase: AuthSessionUseCase
    private let observeSystemThemeUseCase: ObserveSystemThemeUseCase
    
    init(
        sessionUseCase: AuthSessionUseCase,
        observeSystemThemeUseCase: ObserveSystemThemeUseCase
    ) {
        self.sessionUseCase = sessionUseCase
        self.observeSystemThemeUseCase = observeSystemThemeUseCase
        self.state = State()
        
        setupNetworkMonitoring()
        setupSessionMonitoring()
        setupThemeMonitoring()
    }
    
    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []
        
        switch action {
        case .onAppear:
            effects = [.clearApplicationBadgeCount]
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        case .networkStatusChanged(let isConnected):
            let wasConnected = state.isNetworkConnected
            state.isNetworkConnected = isConnected
            if wasConnected && !isConnected {
                setAlert(&state, isPresented: true)
            }
        case .setTheme(let theme):
            state.theme = theme
        case .didLogined(let result):
            state.signIn = result
        }
        
        if self.state != state { self.state = state }
        return effects
    }
    
    func run(_ effect: SideEffect) {
        switch effect {
        case .clearApplicationBadgeCount:
            UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
        }
    }
}

// MARK: - Helper Methods
private extension RootViewModel {
    func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = "네트워크 연결 끊김"
        state.alertMessage = "인터넷 연결을 확인해주세요."
        state.showAlert = isPresented
    }

    func setupNetworkMonitoring() {
        connectivityProvider.isConnectedPublisher
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.send(.networkStatusChanged(isConnected))
            }
            .store(in: &cancellables)
    }

    func setupSessionMonitoring() {
        sessionUseCase.signedInPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] signIn in
                self?.send(.didLogined(signIn))
            }
            .store(in: &cancellables)
    }

    func setupThemeMonitoring() {
        observeSystemThemeUseCase.publisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                self?.send(.setTheme(theme))
            }
            .store(in: &cancellables)
    }
}
