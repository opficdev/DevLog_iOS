//
//  LoginFeature.swift
//  DevLogPresentation
//
//  Created by opfic on 6/5/26.
//

import ComposableArchitecture
import DevLogDomain
import Foundation

@Reducer
struct LoginFeature {
    @ObservableState
    struct State: Equatable {
        var isLoading = false
        var showAlert = false
        var alertType: AlertType?
        var alertTitle = ""
        var alertMessage = ""
    }

    enum Action {
        case setAlert(Bool, AlertType? = nil)
        case tapSignInButton(AuthProvider)
        case signInSucceeded
        case signInFailed(AlertType)
        case signInCancelled
    }

    enum AlertType: Equatable {
        case emailUnavailable
        case error
    }

    @Dependency(\.signInUseCase) var signInUseCase

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .setAlert(let isPresented, let alertType):
                setAlert(&state, isPresented: isPresented, alertType: alertType)
            case .tapSignInButton(let provider):
                state.isLoading = true
                return .run { [signInUseCase] send in
                    do {
                        try await signInUseCase.execute(provider)
                        await send(.signInSucceeded)
                    } catch {
                        if error.isSocialLoginCancelled {
                            await send(.signInCancelled)
                            return
                        }
                        await send(.signInFailed(alertType(for: error)))
                    }
                }
            case .signInSucceeded, .signInCancelled:
                state.isLoading = false
            case .signInFailed(let alertType):
                state.isLoading = false
                setAlert(&state, isPresented: true, alertType: alertType)
            }
            return .none
        }
    }
}

struct SignInUseCaseDependency {
    var execute: (AuthProvider) async throws -> Void

    init(execute: @escaping (AuthProvider) async throws -> Void) {
        self.execute = execute
    }
}

extension SignInUseCaseDependency: DependencyKey {
    static let liveValue = Self { _ in
        preconditionFailure("SignInUseCaseDependency must be provided.")
    }

    static let testValue = liveValue

    static func live(_ signInUseCase: SignInUseCase) -> SignInUseCaseDependency {
        Self {
            try await signInUseCase.execute($0)
        }
    }
}

extension DependencyValues {
    var signInUseCase: SignInUseCaseDependency {
        get { self[SignInUseCaseDependency.self] }
        set { self[SignInUseCaseDependency.self] = newValue }
    }
}

private extension LoginFeature {
    func setAlert(
        _ state: inout State,
        isPresented: Bool,
        alertType: AlertType?
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
}
