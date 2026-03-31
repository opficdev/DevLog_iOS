//
//  LoginViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/14/25.
//

import Foundation

@Observable
final class LoginViewModel: Store {
    struct State: Equatable {
        var isLoading = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
    }

    enum Action {
        case setAlert(Bool)
        case tapSignInButton(AuthProvider)
        case setLoading(Bool)
    }

    enum SideEffect {
        case signIn(AuthProvider)
    }

    private let signInUseCase: SignInUseCase

    private(set) var state = State()

    init(
        signInUseCase: SignInUseCase
    ) {
        self.signInUseCase = signInUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []
        
        switch action {
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        case .tapSignInButton(let authProvider):
            effects = [.signIn(authProvider)]
        case .setLoading(let value):
            state.isLoading = value
        }
        
        if self.state != state { self.state = state }
        return effects
    }

    func run(_ effect: SideEffect) {
        send(.setLoading(true))
        switch effect {
        case .signIn(let authProvider):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    try await self.signInUseCase.execute(authProvider)
                } catch {
                    if error.isSocialLoginCancelled { return }
                    send(.setAlert(true))
                }
            }
        }
    }
}

private extension LoginViewModel {
    func setAlert(
        _ state: inout State,
        isPresented: Bool,
    ) {
        state.alertTitle = String(localized: "common_error_title")
        state.alertMessage = String(localized: "common_error_message")
        state.showAlert = isPresented
    }
}
