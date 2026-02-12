//
//  AccountViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 2/12/26.
//

import Foundation

final class AccountViewModel: Store {
    struct State {
        var currentProvider: String = ""
        var connectedProviders: [String] = []
        var disconnectedProviders: [String] = []
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertType: AlertType?
        var alertMessage: String = ""
        var showToast: Bool = false
        var toastType: ToastType?
        var toastMessage: String = ""
        var isLoading: Bool = false
    }

    enum Action {
        case onAppear
        case linkWithProvider(String)
        case unlinkFromProvider(String)
        case setAlert(isPresented: Bool, type: AlertType? = nil)
        case setToast(isPresented: Bool, type: ToastType? = nil)
        case setLoading(Bool)
    }

    enum SideEffect {
        case link(String)
        case unlink(String)
    }

    enum AlertType {
        case error
    }

    enum ToastType {
        case linkSuccess
        case unlinkSuccess
    }

    @Published private(set) var state: State = .init()

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state

        switch action {
        case .onAppear:
            
        case .linkWithProvider(let value):
            return [.link(value)]
        case .unlinkFromProvider(let value):
            return [.unlink(value)]
        case .setAlert(let isPresented, let type):
            setAlert(&state, isPresented: isPresented, type: type)
        case .setToast(let isPresented, let type):
            setToast(&state, isPresented: isPresented, type: type)
        case .setLoading(let value):
            state.isLoading = value
        }

        self.state = state
        return []
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .link(let provider):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))

                    send(.setToast(isPresented: true, type: .linkSuccess))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .unlink(let provider):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))

                    send(.setToast(isPresented: true, type: .unlinkSuccess))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        }
    }
}

private extension AccountViewModel {
    func setAlert(_ state: inout State, isPresented: Bool, type: AlertType?) {
        switch type {
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

    func setToast(_ state: inout State, isPresented: Bool, type: ToastType?) {
        switch type {
        case .linkSuccess:
            state.toastMessage = "계정이 성공적으로 연결되었습니다."
        case .unlinkSuccess:
            state.toastMessage = "계정 연결이 성공적으로 해제되었습니다."
        case .none:
            state.toastMessage = ""
        }
        state.showToast = isPresented
        state.toastType = type
    }
}
