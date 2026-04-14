//
//  SettingViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation
import Combine

@Observable
final class SettingViewModel: Store {
    struct State: Equatable {
        var theme: SystemTheme = .automatic
        var dirSize: Int64 = 0
        var isNetworkConnected = true
        var isLoading = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertType: AlertType?
        var alertMessage: String = ""
    }

    enum Action {
        case networkStatusChanged(Bool)
        case setAlert(isPresented: Bool, type: AlertType? = nil)
        case setLoading(Bool)
        case setTheme(SystemTheme)
        case updateDirSize
        case tapDeleteAuthButton
        case tapSignOutButton
        case tapRemoveCacheButton
        case confirmRemoveCache
    }

    enum SideEffect {
        case deleteAuth
        case signOut
    }

    enum AlertType {
        case signOut, deleteAuth, error, removeCache
    }

    private(set) var state = State()
    private let deleteAuthuseCase: DeleteAuthUseCase
    private let signOutUseCase: SignOutUseCase
    private let networkConnectivityUseCase: ObserveNetworkConnectivityUseCase
    private let systemThemeUseCase: ObserveSystemThemeUseCase
    private let updateSystemThemeUseCase: UpdateSystemThemeUseCase
    private let fetchWebPageImageDirSizeUseCase: FetchWebPageImageDirSizeUseCase
    private let clearWebPageImageDirectoryUseCase: ClearWebPageImageDirectoryUseCase
    private let loadingState = LoadingState()
    private var cancellables = Set<AnyCancellable>()

    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let appstoreUrl = Bundle.main.object(forInfoDictionaryKey: "APPSTORE_URL") as? String
    let policyURL = Bundle.main.object(forInfoDictionaryKey: "PRIVACY_POLICY_URL") as? String

    init(
        deleteAuthUseCase: DeleteAuthUseCase,
        signOutUseCase: SignOutUseCase,
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase,
        systemThemeUseCase: ObserveSystemThemeUseCase,
        updateSystemThemeUseCase: UpdateSystemThemeUseCase,
        fetchWebPageImageDirSizeUseCase: FetchWebPageImageDirSizeUseCase,
        clearWebPageImageDirectoryUseCase: ClearWebPageImageDirectoryUseCase
    ) {
        self.deleteAuthuseCase = deleteAuthUseCase
        self.signOutUseCase = signOutUseCase
        self.networkConnectivityUseCase = networkConnectivityUseCase
        self.systemThemeUseCase = systemThemeUseCase
        self.updateSystemThemeUseCase = updateSystemThemeUseCase
        self.fetchWebPageImageDirSizeUseCase = fetchWebPageImageDirSizeUseCase
        self.clearWebPageImageDirectoryUseCase = clearWebPageImageDirectoryUseCase
        setupNetworkObserving()
        setupThemeMonitoring()
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .networkStatusChanged(let isConnected):
            state.isNetworkConnected = isConnected
        case .setAlert(let isPresented, let type):
            setAlert(&state, isPresented: isPresented, type: type)
        case .setLoading(let value):
            state.isLoading = value
        case .setTheme(let value):
            state.theme = value
            updateSystemThemeUseCase.execute(value)
        case .updateDirSize:
            state.dirSize = fetchWebPageImageDirSizeUseCase.execute()
        case .tapDeleteAuthButton:
            effects = [.deleteAuth]
        case .tapSignOutButton:
            effects = [.signOut]
        case .tapRemoveCacheButton:
            setAlert(&state, isPresented: true, type: .removeCache)
        case .confirmRemoveCache:
            do {
                setAlert(&state, isPresented: false)
                try clearWebPageImageDirectoryUseCase.execute()
                state.dirSize = fetchWebPageImageDirSizeUseCase.execute()
            } catch {
                setAlert(&state, isPresented: true, type: .error)
            }
        }

        if self.state != state { self.state = state }
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .deleteAuth:
            beginLoading(.delayed)
            Task {
                do {
                    send(.setAlert(isPresented: false))
                    defer { endLoading(.delayed) }
                    try await deleteAuthuseCase.execute()
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
        case .signOut:
            beginLoading(.delayed)
            Task {
                do {
                    send(.setAlert(isPresented: false))
                    defer { endLoading(.delayed) }
                    try await signOutUseCase.execute()
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
        type: AlertType? = nil
    ) {
        switch type {
        case .signOut:
            state.alertTitle = String(localized: "settings_alert_sign_out_title")
            state.alertMessage = String(localized: "settings_alert_sign_out_message")
        case .deleteAuth:
            state.alertTitle = String(localized: "settings_alert_delete_account_title")
            state.alertMessage = String(localized: "settings_alert_delete_account_message")
        case .error:
            state.alertTitle = String(localized: "common_error_title")
            state.alertMessage = String(localized: "common_error_message")
        case .removeCache:
            state.alertTitle = String(localized: "settings_alert_clear_temp_title")
            state.alertMessage = String(localized: "settings_alert_clear_temp_message")
        case .none:
            state.alertTitle = ""
            state.alertMessage = ""
        }
        state.showAlert = isPresented
        state.alertType = type
    }

    func setupThemeMonitoring() {
        systemThemeUseCase.observe()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                self?.send(.setTheme(theme))
            }
            .store(in: &cancellables)
    }

    func setupNetworkObserving() {
        networkConnectivityUseCase.observe()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.send(.networkStatusChanged(isConnected))
            }
            .store(in: &cancellables)
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
