//
//  RootViewModel.swift
//  DevLog
//
//  Created by AI on 2/12/26.
//

import Foundation
import Combine

final class RootViewModel: Store {
    struct State {
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
        var isNetworkConnected: Bool = true
        var isFirstLaunch: Bool
        var signIn: Bool?
    }
    
    enum Action {
        case setAlert(Bool)
        case networkStatusChanged(Bool)
        case setFirstLaunch(Bool)
        case signOutAuto
        case didLogined(Bool)
    }

    enum SideEffect {
        case signOut
    }

    @Published private(set) var state: State
    private let connectivityProvider = NWPathConnectivityProvider()
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let firstLaunchKey = "isFirstLaunch"
    private let sessionUseCase: AuthSessionUseCase
    private let signOutUseCase: SignOutUseCase
    
    init(
        sessionUseCase: AuthSessionUseCase,
        signOutUseCase: SignOutUseCase
    ) {
        let isFirstLaunch = userDefaults.object(forKey: firstLaunchKey) as? Bool ?? true
        self.sessionUseCase = sessionUseCase
        self.signOutUseCase = signOutUseCase
        self.state = State(isFirstLaunch: isFirstLaunch, signIn: nil)
        
        setupNetworkMonitoring()
        setupSessionMonitoring()
    }
    
    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        
        switch action {
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
            userDefaults.set(value, forKey: firstLaunchKey)
            
        case .signOutAuto:
            return [.signOut]
            
        case .didLogined(let result):
            state.signIn = result
        }
        
        self.state = state
        return []
    }
    
    func run(_ effect: SideEffect) {
        switch effect {
        case .signOut:
            Task {
                do {
                    try await signOutUseCase.execute()
                    send(.didLogined(false))
                    sessionUseCase.execute(false)
                } catch {
                    // Silent fail for auto sign out
                }
            }
        }
    }
    
    private func setupNetworkMonitoring() {
        connectivityProvider.isConnectedPublisher
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.send(.networkStatusChanged(isConnected))
            }
            .store(in: &cancellables)
    }
    
    private func setupSessionMonitoring() {
        sessionUseCase.signedInPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] signIn in
                self?.send(.didLogined(signIn))
            }
            .store(in: &cancellables)
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
}
