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
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
    }

    enum Action {
        case signOutAuto
        case setAlert(Bool)
        case tapSignInButton(AuthProvider)
        case tapSignOutButton
        case setLoading(Bool)
        case setLogined(Bool)
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
                self?.send(.setLogined(signIn))
            }
            .store(in: &cancellables)
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        
        switch action {
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        case .tapSignInButton(let authProvider):
            self.state = state
            return [.signIn(authProvider)]
        case .tapSignOutButton, .signOutAuto:
            self.state = state
            return [.signOut]
        case .setLoading(let value):
            state.isLoading = value
        case .setLogined(let result):
            state.signIn = result
        }
        
        self.state = state
        return []
    }

    func run(_ effect: SideEffect) {
        send(.setLoading(true))
        switch effect {
        case .signIn(let authProvider):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    try await self.signInUseCase.execute(authProvider)
                    send(.setLogined(true))
                    sessionUseCase.execute(true)
                } catch {
                    send(.setLogined(false))
                    sessionUseCase.execute(false)
                    send(.setAlert(true))
                }
            }
        case .signOut:
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    try await self.signOutUseCase.execute()
                    send(.setLogined(false))
                    sessionUseCase.execute(false)
                } catch {
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
        state.alertTitle = "오류"
        state.alertMessage = "문제가 발생했습니다. 잠시 후 다시 시도해주세요."
        state.showAlert = isPresented
    }
}
