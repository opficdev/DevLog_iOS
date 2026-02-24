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
        var isLoading = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertType: AlertType?
        var alertMessage: String = ""
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let policyURL = Bundle.main.object(forInfoDictionaryKey: "PRIVACY_POLICY_URL") as? String
    }

    enum Action {
        case setAlert(isPresented: Bool, type: AlertType? = nil)
        case setLoading(Bool)
        case setTheme(String)
        case tapDeleteAuthButton
        case tapSignOutButton
    }

    enum SideEffect {
        case deleteAuth
        case signOut
    }

    enum AlertType {
        case signOut, cancel, error
    }

    @Published private(set) var state = State()
    private let deleteAuthuseCase: DeleteAuthUseCase
    private let signOutUseCase: SignOutUseCase
    private let sessionUseCase: AuthSessionUseCase

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
        case .setAlert(let isPresented, let type):
            setAlert(&state, isPresented: isPresented, type: type)
        case .setLoading(let value):
            state.isLoading = value
        case .setTheme(let value):
            state.theme = value
        case .tapDeleteAuthButton:
            return [.deleteAuth]
        case .tapSignOutButton:
            return [.signOut]
        }
        return []
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .deleteAuth:
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setAlert(isPresented: false))
                    send(.setLoading(true))
                    try await deleteAuthuseCase.execute()
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .signOut:
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setAlert(isPresented: false))
                    send(.setLoading(true))
                    try await signOutUseCase.execute()
                    sessionUseCase.execute(false)
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        }
    }
}

private extension SettingViewModel {
    func setAlert(
        _ state: inout State,
        isPresented: Bool,
        type: AlertType?
    ) {
        switch type {
        case .signOut:
            state.alertTitle = "로그아웃"
            state.alertMessage = "로그아웃 하시겠습니까?"
        case .cancel:
            state.alertTitle = "정말 탈퇴하시겠습니까?"
            state.alertMessage = "회원 탈퇴가 진행되면 모든 데이터가 지워지고 복구할 수 없습니다."
        case .error:
            state.alertTitle = "오류"
            state.alertMessage = "문제가 발생했습니다. 잠시 후 다시 시도해주세요."
        case .none:
            state.alertTitle = ""
            state.alertMessage = ""
        }
        state.showAlert = isPresented
        state.alertType = type
    }
}
