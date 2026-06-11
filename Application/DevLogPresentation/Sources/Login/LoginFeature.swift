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
        @Presents var alert: AlertState<Never>?
        var isLoading = false
    }

    enum Action {
        case alert(PresentationAction<Never>)
        case tapSignInButton(AuthProvider)
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
            case .alert:
                break
            case .tapSignInButton(let provider):
                state.isLoading = true
                return .run { [signInUseCase] send in
                    do {
                        try await signInUseCase.execute(provider)
                    } catch {
                        if error.isSocialLoginCancelled {
                            await send(.signInCancelled)
                            return
                        }
                        await send(.signInFailed(alertType(for: error)))
                    }
                }
            case .signInCancelled:
                state.isLoading = false
            case .signInFailed(let alertType):
                state.isLoading = false
                state.alert = alertState(for: alertType)
            }
            return .none
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension DependencyValues {
    var signInUseCase: SignInUseCase {
        get { self[SignInUseCaseKey.self] }
        set { self[SignInUseCaseKey.self] = newValue }
    }
}

private enum SignInUseCaseKey: DependencyKey {
    static var liveValue: SignInUseCase {
        preconditionFailure("SignInUseCase must be provided.")
    }

    static var testValue: SignInUseCase {
        liveValue
    }
}

private extension LoginFeature {
    func alertState(for alertType: AlertType) -> AlertState<Never> {
        let title: String
        let message: String

        switch alertType {
        case .emailUnavailable:
            title = String(localized: "login_alert_email_unavailable_title")
            message = String(localized: "login_alert_email_unavailable_message")
        case .error:
            title = String(localized: "common_error_title")
            message = String(localized: "common_error_message")
        }

        return AlertState {
            TextState(title)
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close"))
            }
        } message: {
            TextState(message)
        }
    }

    func alertType(for error: Error) -> AlertType {
        if case AuthError.emailNotFound = error {
            return .emailUnavailable
        }

        return .error
    }
}
