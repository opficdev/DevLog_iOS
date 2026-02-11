//
//  LoginViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/14/25.
//

import Combine
import Foundation
import FirebaseAuth
import GoogleSignIn

final class LoginViewModel: Store {
    struct State {
        var signIn: Bool?
        var isLoading = false
        var showToast: Bool = false
        var toastMessage: String = ""
    }

    enum Action {
        case signOutAuto
        case tapCloseToast
        case tapSignInButton(AuthProvider)
        case tapSignOutButton
        case didStartLoading
        case didFinishLoading
        case didLogined(result: Bool)
        case didLoginFail(message: String)
    }

    enum SideEffect {
        case signIn(AuthProvider)
        case signOut
    }

    private let signInUseCase: SignInUseCase
    private let signOutUseCase: SignOutUseCase
    private let sessionUseCase: AuthSessionUseCase

    @Published private(set) var state = State()
    private var cancellables = Set<AnyCancellable>()

    init(
        signInUseCase: SignInUseCase,
        signOutUseCase: SignOutUseCase,
        sessionUseCase: AuthSessionUseCase
    ) {
        self.signInUseCase = signInUseCase
        self.signOutUseCase = signOutUseCase
        self.sessionUseCase = sessionUseCase

        self.sessionUseCase.signedInPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] signIn in
                self?.send(.didLogined(result: signIn))
            }
            .store(in: &cancellables)
    }

    func reduce(with action: Action) -> [SideEffect] {
        switch action {
        case .tapCloseToast:
            state.showToast = false
        case .tapSignInButton(let authProvider):
            return [.signIn(authProvider)]
        case .tapSignOutButton, .signOutAuto:
            return [.signOut]
        case .didStartLoading:
            state.isLoading = true
        case .didFinishLoading:
            state.isLoading = false
        case .didLogined(let result):
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
                    defer { send(.didFinishLoading) }

                    _ = try await self.signInUseCase.execute(authProvider)

                    send(.didFinishLoading)
                    send(.didLogined(result: true))
                    sessionUseCase.execute(true)
                } catch {
                    send(.didFinishLoading)
                    send(.didLogined(result: false))
                    sessionUseCase.execute(false)
                    send(.didLoginFail(message: error.localizedDescription))
                }
            }
        case .signOut:
            Task {
                send(.didStartLoading)
                do {
                    defer { send(.didFinishLoading) }
                    try await self.signOutUseCase.execute()
                    send(.didLogined(result: false))
                    sessionUseCase.execute(false)
                } catch {
                    send(.didFinishLoading)
                    send(.didLoginFail(message: error.localizedDescription))
                }
            }
        }
    }
}
