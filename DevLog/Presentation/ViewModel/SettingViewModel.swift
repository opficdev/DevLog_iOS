//
//  SettingViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation

final class SettingViewModel: Store {
    struct State {
        var theme = ""
        var showDeleteUserAlert = false
        var showSignOutAlert = false
        var toastMessage = ""
        var showToast = false
        var isLoading = false
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    enum Action {
        case toggleToast(Bool)
        case setLoading(Bool)
        case setTheme(String)
        case setToastMessage(String)
        case tapDeleteAuthButton
        case tapSignOutButton
        case toggleDeleteUserAlert(Bool)
        case toggleSignOutAlert(Bool)
    }

    enum SideEffect {
        case deleteAuth
        case signOut
    }

    private let deleteAuthuseCase: DeleteAuthUseCase
    private let signOutUseCase: SignOutUseCase
    private let sessionUseCase: AuthSessionUseCase

    @Published private(set) var state = State()

    init(
        deleteAuthUseCase: DeleteAuthUseCase,
        signOutUseCase: SignOutUseCase,
        sessionUseCase: AuthSessionUseCase
    ) {
        self.deleteAuthuseCase = deleteAuthUseCase
        self.signOutUseCase = signOutUseCase
        self.sessionUseCase = sessionUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        switch action {
        case .toggleToast(let value):
            state.showToast = value
        case .setLoading(let value):
            state.isLoading = value
        case .setTheme(let value):
            state.theme = value
        case .setToastMessage(let message):
            state.toastMessage = message
        case .tapDeleteAuthButton:
            break
        case .tapSignOutButton:
            return [.signOut]
        case .toggleDeleteUserAlert(let value):
            state.showDeleteUserAlert = value
        case .toggleSignOutAlert(let value):
            state.showSignOutAlert = value
        }
        return []
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .deleteAuth:
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.toggleDeleteUserAlert(false))
                    send(.setLoading(true))
                    try await deleteAuthuseCase.execute()
                } catch {
                    send(.toggleToast(true))
                    send(.setToastMessage(error.localizedDescription))
                }
            }
        case .signOut:
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.toggleSignOutAlert(false))
                    send(.setLoading(true))
                    try await signOutUseCase.execute()
                    sessionUseCase.execute(false)
                } catch {
                    send(.toggleToast(true))
                    send(.setToastMessage(error.localizedDescription))
                }
            }
        }
    }
}
