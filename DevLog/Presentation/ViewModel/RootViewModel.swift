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
        var isFirstLaunch: Bool
        var signIn: Bool?
        var theme: SystemTheme = .automatic
    }
    
    enum Action {
        case onAppear
        case setAlert(Bool)
        case networkStatusChanged(Bool)
        case setFirstLaunch(Bool)
        case setTheme(SystemTheme)
        case signOutAuto
        case didLogined(Bool)
    }

    enum SideEffect {
        case clearApplicationBadgeCount
        case signOut
    }

    private(set) var state: State
    private let connectivityProvider = NWPathConnectivityProvider()
    private var cancellables = Set<AnyCancellable>()
    private let sessionUseCase: AuthSessionUseCase
    private let signOutUseCase: SignOutUseCase
    private let fetchFirstLaunchUseCase: FetchFirstLaunchUseCase
    private let updateFirstLaunchUseCase: UpdateFirstLaunchUseCase
    private let observeSystemThemeUseCase: ObserveSystemThemeUseCase
    private let updateSystemThemeUseCase: UpdateSystemThemeUseCase
    
    init(
        sessionUseCase: AuthSessionUseCase,
        signOutUseCase: SignOutUseCase,
        fetchFirstLaunchUseCase: FetchFirstLaunchUseCase,
        updateFirstLaunchUseCase: UpdateFirstLaunchUseCase,
        observeSystemThemeUseCase: ObserveSystemThemeUseCase,
        updateSystemThemeUseCase: UpdateSystemThemeUseCase
    ) {
        let isFirstLaunch = fetchFirstLaunchUseCase.execute()
        self.sessionUseCase = sessionUseCase
        self.signOutUseCase = signOutUseCase
        self.fetchFirstLaunchUseCase = fetchFirstLaunchUseCase
        self.updateFirstLaunchUseCase = updateFirstLaunchUseCase
        self.observeSystemThemeUseCase = observeSystemThemeUseCase
        self.updateSystemThemeUseCase = updateSystemThemeUseCase
        self.state = State(isFirstLaunch: isFirstLaunch)
        
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
            if state.isFirstLaunch {
                state.isFirstLaunch = false
                updateFirstLaunchUseCase.execute(false)
                effects.append(.signOut)
            }
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        case .networkStatusChanged(let isConnected):
            let wasConnected = state.isNetworkConnected
            state.isNetworkConnected = isConnected
            if wasConnected && !isConnected {
                setAlert(&state, isPresented: true)
            }
        case .setFirstLaunch(let value):
            state.isFirstLaunch = value
            updateFirstLaunchUseCase.execute(value)
        case .setTheme(let theme):
            state.theme = theme
        case .signOutAuto:
            effects = [.signOut]
        case .didLogined(let result):
            state.signIn = result
        }
        
        if self.state != state { self.state = state }
        return effects
    }
    
    func run(_ effect: SideEffect) {
        switch effect {
        case .clearApplicationBadgeCount:
            clearApplicationBadgeCount()
        case .signOut:
            Task {
                try? await signOutUseCase.execute()
                send(.didLogined(false))
                sessionUseCase.execute(false)
            }
        }
    }
}

// MARK: - Helper Methods
private extension RootViewModel {
    func clearApplicationBadgeCount() {
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    }

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
