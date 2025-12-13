//
//  LoginViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/14/25.
//

import Foundation

final class LoginViewModel: Store {
    struct State {
        var signIn: Bool?
        var isLoading = false
        var showToast: Bool = false
        var toastMessage: String = ""
    }

    enum Action {
        case didTapSignInButton(AuthProvider)
        case didStartLoading
        case didFinishLoading
        case didLoginSucceed(result: Bool)
        case didLoginFail(message: String)
    }

    enum SideEffect {
        case signIn(AuthProvider)
    }

    private let signInWithAppleUseCase: any SignInUseCase
    private let signInWithGithubUseCase: any SignInUseCase
    private let signInWithGoogleUseCase: any SignInUseCase
    @Published private(set) var state = State()

    init(
        signInWithAppleUseCase: any SignInUseCase,
        signInWithGithubUseCase: any SignInUseCase,
        signInWithGoogleUseCase: any SignInUseCase
    ) {
        self.signInWithAppleUseCase = signInWithAppleUseCase
        self.signInWithGithubUseCase = signInWithGithubUseCase
        self.signInWithGoogleUseCase = signInWithGoogleUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        switch action {
        case .didTapSignInButton(let authProvider):
            return [.signIn(authProvider)]
        case .didStartLoading:
            state.isLoading = true
        case .didFinishLoading:
            state.isLoading = false
        case .didLoginSucceed(let result):
            state.signIn = result
        case .didLoginFail(let message):
            state.toastMessage = message
            state.showToast = true
        }
        return []
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .signIn(let authProvider):
            Task {
                send(.didStartLoading)
                do {
                    defer {
                        send(.didFinishLoading)
                        send(.didLoginSucceed(result: false))
                    }
                    switch authProvider {
                    case .apple:
                        _ = try await self.signInWithAppleUseCase.execute()
                    case .github:
                        _ = try await self.signInWithGithubUseCase.execute()
                    case .google:
                        _ = try await self.signInWithGoogleUseCase.execute()
                    }

                    send(.didFinishLoading)
                    send(.didLoginSucceed(result: true))
                } catch {
                    send(.didFinishLoading)
                    send(.didLoginFail(message: error.localizedDescription))
                }
            }
        }
    }
}
