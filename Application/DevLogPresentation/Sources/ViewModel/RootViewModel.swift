//
//  RootViewModel.swift
//  DevLogPresentation
//
//  Created by AI on 2/12/26.
//

import Foundation
import Combine
import UserNotifications
import DevLogCore
import DevLogDomain

@Observable
public final class RootViewModel: Store {
    public struct State: Equatable {
        public var showAlert: Bool = false
        public var alertTitle: String = ""
        public var alertMessage: String = ""
        public var isNetworkConnected: Bool = true
        public var signIn: Bool?
        public var theme: SystemTheme = .automatic
    }
    
    public enum Action {
        case onAppear
        case setAlert(Bool)
        case networkStatusChanged(Bool)
        case setTheme(SystemTheme)
        case didLogined(Bool)
    }

    public enum SideEffect {
        case clearApplicationBadgeCount
        case trackLoginScreen
    }

    public private(set) var state: State
    private var cancellables = Set<AnyCancellable>()
    private let sessionUseCase: ObserveAuthSessionUseCase
    private let networkConnectivityUseCase: ObserveNetworkConnectivityUseCase
    private let systemThemeUseCase: ObserveSystemThemeUseCase
    private let trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase
    
    public init(
        sessionUseCase: ObserveAuthSessionUseCase,
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase,
        systemThemeUseCase: ObserveSystemThemeUseCase,
        trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase
    ) {
        self.sessionUseCase = sessionUseCase
        self.networkConnectivityUseCase = networkConnectivityUseCase
        self.systemThemeUseCase = systemThemeUseCase
        self.trackAnalyticsEventUseCase = trackAnalyticsEventUseCase
        self.state = State()
        
        setupNetworkObserving()
        setupSessionObserving()
        setupThemeObserving()
    }
    
    public func reduce(with action: Action) -> [SideEffect] {
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
            if !result {
                effects = [.trackLoginScreen]
            }
        }
        
        if self.state != state { self.state = state }
        return effects
    }
    
    public func run(_ effect: SideEffect) {
        switch effect {
        case .clearApplicationBadgeCount:
            UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
        case .trackLoginScreen:
            trackAnalyticsEventUseCase.execute(.screenView("login"))
        }
    }
}

// MARK: - Helper Methods
private extension RootViewModel {
    func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = String(localized: "root_network_disconnected_title")
        state.alertMessage = String(localized: "root_network_disconnected_message")
        state.showAlert = isPresented
    }

    func setupNetworkObserving() {
        networkConnectivityUseCase.observe()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.send(.networkStatusChanged(isConnected))
            }
            .store(in: &cancellables)
    }

    func setupSessionObserving() {
        sessionUseCase.observe()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] signIn in
                self?.send(.didLogined(signIn))
            }
            .store(in: &cancellables)
    }

    func setupThemeObserving() {
        systemThemeUseCase.observe()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                self?.send(.setTheme(theme))
            }
            .store(in: &cancellables)
    }
}
