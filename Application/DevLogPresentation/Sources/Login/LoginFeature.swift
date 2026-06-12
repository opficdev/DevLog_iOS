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
        var loading = LoadingFeature.State()

        var isLoading: Bool {
            loading.isLoading
        }
    }

    enum Action {
        case alert(PresentationAction<Never>)
        case tapSignInButton(AuthProvider)
        case signInFailed(AlertType)
        case loading(LoadingFeature.Action)
    }

    enum AlertType: Equatable {
        case emailUnavailable
        case error
    }

    @Dependency(\.signInUseCase) var signInUseCase

    var body: some ReducerOf<Self> {
        Scope(state: \.loading, action: \.loading) {
            LoadingFeature()
        }
        Reduce { state, action in
            switch action {
            case .alert:
                break
            case .tapSignInButton(let provider):
                return signInEffect(provider)
            case .signInFailed(let alertType):
                state.alert = Self.alertState(for: alertType)
            case .loading:
                break
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
    func signInEffect(_ provider: AuthProvider) -> Effect<Action> {
        .run { [signInUseCase] send in
            await send(.loading(.begin(target: .default, mode: .immediate)))
            do {
                try await signInUseCase.execute(provider)
            } catch {
                await send(.loading(.end(target: .default, mode: .immediate)))
                if error.isSocialLoginCancelled { return }
                await send(.signInFailed(Self.alertType(for: error)))
            }
        }
    }

    static func alertState(for alertType: AlertType) -> AlertState<Never> {
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

    static func alertType(for error: Error) -> AlertType {
        if case AuthError.emailNotFound = error {
            return .emailUnavailable
        }

        return .error
    }
}
