//
//  AccountViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 2/12/26.
//

import Foundation

@Observable
final class AccountViewModel: Store {
    struct State {
        var currentProvider: AuthProvider?
        var connectedProviders: [AuthProvider] = []
        var disconnectedProviders: [AuthProvider] = []
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
        case linkWithProvider(AuthProvider)
        case unlinkFromProvider(AuthProvider)
        case setAlert(isPresented: Bool, type: AlertType? = nil)
        case setToast(isPresented: Bool, type: ToastType? = nil)
        case setLoading(Bool)
        case updateProviders(currentProvider: AuthProvider?, allProviders: [AuthProvider])
    }

    enum SideEffect {
        case fetch
        case link(AuthProvider)
        case unlink(AuthProvider)
    }

    enum AlertType {
        case error
    }

    enum ToastType {
        case linkSuccess
        case unlinkSuccess
    }

    private(set) var state: State = .init()
    private let fetchProvidersUseCase: FetchAuthProvidersUseCase
    private let linkProviderUseCase: LinkAuthProviderUseCase
    private let unlinkProviderUseCase: UnlinkAuthProviderUseCase

    init(
        fetchProvidersUseCase: FetchAuthProvidersUseCase,
        linkProviderUseCase: LinkAuthProviderUseCase,
        unlinkProviderUseCase: UnlinkAuthProviderUseCase
    ) {
        self.fetchProvidersUseCase = fetchProvidersUseCase
        self.linkProviderUseCase = linkProviderUseCase
        self.unlinkProviderUseCase = unlinkProviderUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .onAppear:
            effects = [.fetch]
        case .linkWithProvider(let value):
            effects = [.link(value)]
        case .unlinkFromProvider(let value):
            effects = [.unlink(value)]
        case .setAlert(let isPresented, let type):
            setAlert(&state, isPresented: isPresented, type: type)
        case .setToast(let isPresented, let type):
            setToast(&state, isPresented: isPresented, type: type)
        case .setLoading(let value):
            state.isLoading = value
        case .updateProviders(let currentProvider, let allProviders):
            state.currentProvider = currentProvider
            state.connectedProviders = allProviders.filter { $0 != currentProvider }
            state.disconnectedProviders = AuthProvider.allCases
                .filter { !allProviders.contains($0) }
        }

        self.state = state
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetch:
            Task {
                do {
                    let (currentProvider, allProviders) = try await fetchProvidersUseCase.execute()
                    send(.updateProviders(currentProvider: currentProvider, allProviders: allProviders))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .link(let provider):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    
                    try await linkProviderUseCase.execute(provider)
                    send(.setToast(isPresented: true, type: .linkSuccess))

                    let (currentProvider, allProviders) = try await fetchProvidersUseCase.execute()
                    send(.updateProviders(currentProvider: currentProvider, allProviders: allProviders))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .unlink(let provider):
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    
                    try await unlinkProviderUseCase.execute(provider)
                    send(.setToast(isPresented: true, type: .unlinkSuccess))
                    
                    let (currentProvider, allProviders) = try await fetchProvidersUseCase.execute()
                    send(.updateProviders(currentProvider: currentProvider, allProviders: allProviders))
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
