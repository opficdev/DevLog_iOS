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
    private let sessionUseCase: AuthSessionUseCase
    private let observeSystemThemeUseCase: ObserveSystemThemeUseCase
    private let updateSystemThemeUseCase: UpdateSystemThemeUseCase
    private var cancellables = Set<AnyCancellable>()

    init(
        deleteAuthUseCase: DeleteAuthUseCase,
        signOutUseCase: SignOutUseCase,
        sessionUseCase: AuthSessionUseCase,
        observeSystemThemeUseCase: ObserveSystemThemeUseCase,
        updateSystemThemeUseCase: UpdateSystemThemeUseCase
    ) {
        self.deleteAuthuseCase = deleteAuthUseCase
        self.signOutUseCase = signOutUseCase
        self.sessionUseCase = sessionUseCase
        self.observeSystemThemeUseCase = observeSystemThemeUseCase
        self.updateSystemThemeUseCase = updateSystemThemeUseCase
        setupThemeMonitoring()
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .setAlert(let isPresented, let type):
            setAlert(&state, isPresented: isPresented, type: type)
        case .setLoading(let value):
            state.isLoading = value
        case .setTheme(let value):
            state.theme = value
            updateSystemThemeUseCase.execute(value)
        case .updateDirSize:
            state.dirSize = dirSizeInBytes()
        case .tapDeleteAuthButton:
            effects = [.deleteAuth]
        case .tapSignOutButton:
            effects = [.signOut]
        case .tapRemoveCacheButton:
            setAlert(&state, isPresented: true, type: .removeCache)
        case .confirmRemoveCache:
            do {
                setAlert(&state, isPresented: false)
                try clearCacheDirectory()
                state.dirSize = dirSizeInBytes()
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
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setAlert(isPresented: false))
                    send(.setLoading(true))
                    try await deleteAuthuseCase.execute()
                    sessionUseCase.execute(false)
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
        type: AlertType? = nil
    ) {
        switch type {
        case .signOut:
            state.alertTitle = "로그아웃"
            state.alertMessage = "로그아웃 하시겠습니까?"
        case .deleteAuth:
            state.alertTitle = "정말 탈퇴하시겠습니까?"
            state.alertMessage = "회원 탈퇴가 진행되면 모든 데이터가 지워지고 복구할 수 없습니다."
        case .error:
            state.alertTitle = "오류"
            state.alertMessage = "문제가 발생했습니다. 잠시 후 다시 시도해주세요."
        case .removeCache:
            state.alertTitle = "임시 데이터 삭제"
            state.alertMessage = "임시 데이터를 삭제하고 정리합니다.\n계속하시겠습니까?"
        case .none:
            state.alertTitle = ""
            state.alertMessage = ""
        }
        state.showAlert = isPresented
        state.alertType = type
    }

    func setupThemeMonitoring() {
        observeSystemThemeUseCase.publisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                self?.send(.setTheme(theme))
            }
            .store(in: &cancellables)
    }

    func dirSizeInBytes() -> Int64 {
        do {
            let cachesDir = try FileManager.default.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            guard FileManager.default.fileExists(atPath: cachesDir.path) else { return 0 }
            return directorySize(at: cachesDir)
        } catch {
            return 0
        }
    }

    private func directorySize(at url: URL) -> Int64 {
        guard FileManager.default.fileExists(atPath: url.path) else { return 0 }
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  resourceValues.isRegularFile == true,
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            total += Int64(fileSize)
        }
        return total
    }

    private func clearCacheDirectory() throws {
        let cachesDir = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        guard FileManager.default.fileExists(atPath: cachesDir.path) else { return }
        let contents = try FileManager.default.contentsOfDirectory(
            at: cachesDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        for url in contents {
            try FileManager.default.removeItem(at: url)
        }
    }
}
