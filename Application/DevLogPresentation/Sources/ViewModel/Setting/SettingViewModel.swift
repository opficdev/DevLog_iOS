//
//  SettingViewModel.swift
//  DevLogPresentation
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation
import Combine
import DevLogCore
import DevLogDomain

@Observable
public final class SettingViewModel: Store {
    public typealias Theme = SystemTheme

    public struct State: Equatable {
        public var theme: SystemTheme = .automatic
        public var dirSize: Int64 = 0
        public var isNetworkConnected = true
        public var isLoading = false
        public var showAlert: Bool = false
        public var alertTitle: String = ""
        public var alertType: AlertType?
        public var alertMessage: String = ""
    }

    public enum Action {
        case networkStatusChanged(Bool)
        case setAlert(isPresented: Bool, type: AlertType? = nil)
        case setDirSize(Int64)
        case setLoading(Bool)
        case setTheme(SystemTheme)
        case updateDirSize
        case tapDeleteAuthButton
        case tapSignOutButton
        case tapRemoveCacheButton
        case confirmRemoveCache
    }

    public enum SideEffect {
        case clearWebPageImageDirectory
        case deleteAuth
        case fetchWebPageImageDirSize
        case signOut
    }

    public enum AlertType {
        case signOut, deleteAuth, error, removeCache
    }

    public private(set) var state = State()
    private let deleteAuthuseCase: DeleteAuthUseCase
    private let signOutUseCase: SignOutUseCase
    private let networkConnectivityUseCase: ObserveNetworkConnectivityUseCase
    private let systemThemeUseCase: ObserveSystemThemeUseCase
    private let updateSystemThemeUseCase: UpdateSystemThemeUseCase
    private let fetchWebPageImageDirSizeUseCase: FetchWebPageImageDirSizeUseCase
    private let clearWebPageImageDirectoryUseCase: ClearWebPageImageDirectoryUseCase
    private let loadingState = LoadingState()
    private var cancellables = Set<AnyCancellable>()

    public let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    public let appstoreUrl = Bundle.main.object(forInfoDictionaryKey: "APPSTORE_URL") as? String
    public let policyURL = Bundle.main.object(forInfoDictionaryKey: "PRIVACY_POLICY_URL") as? String

    public init(
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

    public func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .networkStatusChanged(let isConnected):
            state.isNetworkConnected = isConnected
        case .setAlert(let isPresented, let type):
            setAlert(&state, isPresented: isPresented, type: type)
        case .setDirSize(let value):
            state.dirSize = value
        case .setLoading(let value):
            state.isLoading = value
        case .setTheme(let value):
            state.theme = value
            updateSystemThemeUseCase.execute(value)
        case .updateDirSize:
            effects = [.fetchWebPageImageDirSize]
        case .tapDeleteAuthButton:
            effects = [.deleteAuth]
        case .tapSignOutButton:
            effects = [.signOut]
        case .tapRemoveCacheButton:
            setAlert(&state, isPresented: true, type: .removeCache)
        case .confirmRemoveCache:
            setAlert(&state, isPresented: false)
            effects = [.clearWebPageImageDirectory]
        }

        if self.state != state { self.state = state }
        return effects
    }

    public func run(_ effect: SideEffect) {
        switch effect {
        case .clearWebPageImageDirectory:
            Task {
                do {
                    try await clearWebPageImageDirectoryUseCase.execute()
                    let dirSize = await fetchWebPageImageDirSizeUseCase.execute()
                    send(.setDirSize(dirSize))
                } catch {
                    send(.setAlert(isPresented: true, type: .error))
                }
            }
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
        case .fetchWebPageImageDirSize:
            Task {
                let dirSize = await fetchWebPageImageDirSizeUseCase.execute()
                send(.setDirSize(dirSize))
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
