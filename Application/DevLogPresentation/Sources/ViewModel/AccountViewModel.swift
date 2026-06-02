//
//  AccountViewModel.swift
//  DevLogPresentation
//
//  Created by 최윤진 on 2/12/26.
//

import Foundation
import DevLogDomain

@Observable
public final class AccountViewModel: Store {
    public typealias Provider = AuthProvider

    public struct State: Equatable {
        public var currentProvider: AuthProvider?
        public var connectedProviders: [AuthProvider] = []
        public var disconnectedProviders: [AuthProvider] = []
        public var showAlert: Bool = false
        public var alertTitle: String = ""
        public var alertType: AlertType?
        public var alertMessage: String = ""
        public var showToast: Bool = false
        public var toastType: ToastType?
        public var toastMessage: String = ""
        public var isLoading: Bool = false
    }

    public enum Action {
        case onAppear
        case linkWithProvider(AuthProvider)
        case unlinkFromProvider(AuthProvider)
        case setAlert(isPresented: Bool, type: AlertType? = nil)
        case setToast(isPresented: Bool, type: ToastType? = nil)
        case setLoading(Bool)
        case updateProviders(currentProvider: AuthProvider?, allProviders: [AuthProvider])
    }

    public enum SideEffect {
        case fetch
        case link(AuthProvider)
        case unlink(AuthProvider)
    }

    public enum AlertType {
        case linkEmailNotFound
        case linkEmailMismatch
        case linkCredentialAlreadyInUse
        case error
    }

    public enum ToastType {
        case linkSuccess
        case unlinkSuccess
    }

    public private(set) var state: State = .init()
    private let fetchProvidersUseCase: FetchAuthProvidersUseCase
    private let linkProviderUseCase: LinkAuthProviderUseCase
    private let unlinkProviderUseCase: UnlinkAuthProviderUseCase
    private let loadingState = LoadingState()

    public init(
        fetchProvidersUseCase: FetchAuthProvidersUseCase,
        linkProviderUseCase: LinkAuthProviderUseCase,
        unlinkProviderUseCase: UnlinkAuthProviderUseCase
    ) {
        self.fetchProvidersUseCase = fetchProvidersUseCase
        self.linkProviderUseCase = linkProviderUseCase
        self.unlinkProviderUseCase = unlinkProviderUseCase
    }

    public func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .onAppear:
            effects = [.fetch]
        case .linkWithProvider(let value):
            effects = [.link(value)]
        case .unlinkFromProvider(let value):
            effects = [.unlink(value)]
        case .setAlert(let presented, let type):
            setAlert(&state, isPresented: presented, type: type)
        case .setToast(let presented, let type):
            setToast(&state, isPresented: presented, type: type)
        case .setLoading(let value):
            state.isLoading = value
        case .updateProviders(let currentProvider, let allProviders):
            state.currentProvider = currentProvider
            state.connectedProviders = allProviders.filter { $0 != currentProvider }
            state.disconnectedProviders = AuthProvider.allCases
                .filter { !allProviders.contains($0) }
        }

        if self.state != state { self.state = state }
        return effects
    }

    public func run(_ effect: SideEffect) {
        switch effect {
        case .fetch:
            Task {
                do {
                    let(currentProvider, allProviders) = try await fetchProvidersUseCase.execute()
                    send(.updateProviders(currentProvider: currentProvider, allProviders: allProviders))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .link(let provider):
            beginLoading(.delayed)
            Task {
                do {
                    defer { endLoading(.delayed) }
                    try await linkProviderUseCase.execute(provider)
                    send(.setToast(isPresented: true, type: .linkSuccess))

                    let(currentProvider, allProviders) = try await fetchProvidersUseCase.execute()
                    send(.updateProviders(currentProvider: currentProvider, allProviders: allProviders))
                } catch {
                    if error.isSocialLoginCancelled { return }
                    send(.setAlert(isPresented: true, type: linkAlertType(for: error)))
                }
            }
        case .unlink(let provider):
            beginLoading(.delayed)
            Task {
                do {
                    defer { endLoading(.delayed) }
                    try await unlinkProviderUseCase.execute(provider)
                    send(.setToast(isPresented: true, type: .unlinkSuccess))
                    
                    let(currentProvider, allProviders) = try await fetchProvidersUseCase.execute()
                    send(.updateProviders(currentProvider: currentProvider, allProviders: allProviders))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        }
    }
}

private extension AccountViewModel {
    func linkAlertType(for error: Error) -> AlertType {
        guard let authError = error as? AuthError else {
            return .error
        }

        switch authError {
        case .linkEmailNotFound:
            return .linkEmailNotFound
        case .linkEmailMismatch:
            return .linkEmailMismatch
        case .linkCredentialAlreadyInUse:
            return .linkCredentialAlreadyInUse
        case .notAuthenticated, .failedToUnlinkLastProvider, .emailNotFound, .unsupportedProvider:
            return .error
        }
    }

    func setAlert(_ state: inout State, isPresented: Bool, type: AlertType?) {
        switch type {
        case .linkEmailNotFound:
            state.alertTitle = String(localized: "account_alert_email_unavailable_title")
            state.alertMessage = String(localized: "account_alert_email_unavailable_message")
        case .linkEmailMismatch:
            state.alertTitle = String(localized: "account_alert_cannot_link_title")
            state.alertMessage = String(localized: "account_alert_cannot_link_message")
        case .linkCredentialAlreadyInUse:
            state.alertTitle = String(localized: "account_alert_already_linked_title")
            state.alertMessage = String(localized: "account_alert_already_linked_message")
        case .error:
            state.alertTitle = String(localized: "common_error_title")
            state.alertMessage = String(localized: "common_error_message")
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
            state.toastMessage = String(localized: "account_toast_link_success")
        case .unlinkSuccess:
            state.toastMessage = String(localized: "account_toast_unlink_success")
        case .none:
            state.toastMessage = ""
        }
        state.showToast = isPresented
        state.toastType = type
    }

    private func beginLoading(_ mode: LoadingState.Mode) {
        loadingState.begin(mode: mode) { [weak self] isLoading in
            self?.send(.setLoading(isLoading))
        }
    }

    private func endLoading(_ mode: LoadingState.Mode) {
        loadingState.end(mode: mode) { [weak self] isLoading in
            self?.send(.setLoading(isLoading))
        }
    }
}
