//
//  LoginViewModel.swift
//  DevLogPresentation
//
//  Created by 최윤진 on 11/14/25.
//

import Foundation
import DevLogDomain

@Observable
public final class LoginViewModel: Store {
    public struct State: Equatable {
        public var isLoading = false
        public var showAlert: Bool = false
        public var alertType: AlertType?
        public var alertTitle: String = ""
        public var alertMessage: String = ""
    }

    public enum Action {
        case setAlert(Bool, AlertType? = nil)
        case tapSignInButton(AuthProvider)
        case setLoading(Bool)
    }

    public enum SideEffect {
        case signIn(AuthProvider)
    }

    public enum AlertType {
        case emailUnavailable
        case error
    }

    private let signInUseCase: SignInUseCase
    private let loadingState = LoadingState()

    public private(set) var state = State()

    public init(
        signInUseCase: SignInUseCase
    ) {
        self.signInUseCase = signInUseCase
    }

    public func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []
        
        switch action {
        case .setAlert(let isPresented, let alertType):
            setAlert(&state, isPresented: isPresented, alertType: alertType)
        case .tapSignInButton(let authProvider):
            effects = [.signIn(authProvider)]
        case .setLoading(let value):
            state.isLoading = value
        }
        
        if self.state != state { self.state = state }
        return effects
    }

    public func run(_ effect: SideEffect) {
        switch effect {
        case .signIn(let authProvider):
            beginLoading(.immediate)
            Task {
                do {
                    defer { endLoading(.immediate) }
                    try await self.signInUseCase.execute(authProvider)
                } catch {
                    if error.isSocialLoginCancelled { return }
                    send(.setAlert(true, alertType(for: error)))
                }
            }
        }
    }
}

private extension LoginViewModel {
    func setAlert(
        _ state: inout State,
        isPresented: Bool,
        alertType: AlertType?,
    ) {
        switch alertType {
        case .emailUnavailable:
            state.alertTitle = String(localized: "login_alert_email_unavailable_title")
            state.alertMessage = String(localized: "login_alert_email_unavailable_message")
        case .error:
            state.alertTitle = String(localized: "common_error_title")
            state.alertMessage = String(localized: "common_error_message")
        case .none:
            state.alertTitle = ""
            state.alertMessage = ""
        }
        state.showAlert = isPresented
        state.alertType = alertType
    }

    func alertType(for error: Error) -> AlertType {
        if case AuthError.emailNotFound = error {
            return .emailUnavailable
        }

        return .error
    }

    func beginLoading(_ mode: LoadingState.Mode) {
        loadingState.begin(mode: mode) { [weak self] isLoading in
            self?.send(.setLoading(isLoading))
        }
    }

    func endLoading(_ mode: LoadingState.Mode) {
        loadingState.end(mode: mode) { [weak self] isLoading in
            self?.send(.setLoading(isLoading))
        }
    }
}
