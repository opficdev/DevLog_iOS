//
//  PushNotificationSettingsViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 1/18/26.
//

import Foundation
import DevLogDomain
import DevLogDataCommon

@Observable
final class PushNotificationSettingsViewModel: Store {
    struct State: Equatable {
        var pushNotificationEnable: Bool = false
        var viewPushNotificationTime: Date = .init()
        var sheetPushNotificationTime: Date = .init()
        var showTimePicker: Bool = false
        var isLoading: Bool = false
        var sheetHeight: CGFloat = .pi
        var showSheet: Bool = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
        var pushNotificationHour: Int {
            Calendar.current.component(.hour, from: viewPushNotificationTime)
        }
        var pushNotificationMinute: Int {
            Calendar.current.component(.minute, from: viewPushNotificationTime)
        }
    }

    enum Action {
        case fetchSettings
        case setAlert(Bool)
        case setLoading(Bool)
        case setPushNotificationEnable(Bool)
        case setPushNotificationTime(view: Date? = nil, sheet: Date? = nil)
        case setShowTimePicker(Bool)
        case setSheetHeight(CGFloat)
        case selectPresetTime(Date)
        case confirmUpdate
        case rollbackUpdate
    }

    enum SideEffect {
        case fetchPushNotificationSettings
        case updatePushNotificationSettings
    }

    private(set) var state: State = .init()
    private let calendar = Calendar.current
    private let fetchPushSettingsUseCase: FetchPushSettingsUseCase
    private let updatePushSettingsUseCase: UpdatePushSettingsUseCase
    private let loadingState = LoadingState()

    init(
        fetchPushSettingsUseCase: FetchPushSettingsUseCase,
        updatePushSettingsUseCase: UpdatePushSettingsUseCase
    ) {
        self.fetchPushSettingsUseCase = fetchPushSettingsUseCase
        self.updatePushSettingsUseCase = updatePushSettingsUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        var effects: [SideEffect] = []

        switch action {
        case .fetchSettings:
            effects = [.fetchPushNotificationSettings]
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        case .setLoading(let value):
            state.isLoading = value
        case .setPushNotificationEnable(let value):
            state.pushNotificationEnable = value
            effects = [.updatePushNotificationSettings]
        case .setPushNotificationTime(let view, let sheet):
            if let value = view {
                state.viewPushNotificationTime = value
            }
            if let value = sheet {
                state.sheetPushNotificationTime = value
            }
        case .setShowTimePicker(let value):
            state.showTimePicker = value
            if !value {
                state.sheetPushNotificationTime = state.viewPushNotificationTime
            }
        case .setSheetHeight(let value):
            state.sheetHeight = value
        case .selectPresetTime(let date):
            state.viewPushNotificationTime = date
            state.sheetPushNotificationTime = date
            effects = [.updatePushNotificationSettings]
        case .confirmUpdate:
            state.showTimePicker = false
            state.viewPushNotificationTime = state.sheetPushNotificationTime
            effects = [.updatePushNotificationSettings]
        case .rollbackUpdate:
            state.showTimePicker = false
            state.sheetPushNotificationTime = state.viewPushNotificationTime
        }
        if self.state != state { self.state = state }
        return effects
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetchPushNotificationSettings:
            beginLoading(.delayed)
            Task {
                do {
                    defer { endLoading(.delayed) }
                    let settings = try await fetchPushSettingsUseCase.execute()
                    self.send(.setPushNotificationEnable(settings.isEnabled))
                    if let hour = settings.scheduledTime.hour,
                       let minute = settings.scheduledTime.minute,
                       let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) {
                        self.send(.setPushNotificationTime(view: date, sheet: date))
                    }
                } catch {
                    send(.setAlert(true))
                }
            }
        case .updatePushNotificationSettings:
            beginLoading(.delayed)
            Task {
                do {
                    defer { endLoading(.delayed) }
                    let dateComponents = calendar.dateComponents(
                        [.hour, .minute],
                        from: state.sheetPushNotificationTime
                    )
                    let settings = PushNotificationSettings(
                        isEnabled: state.pushNotificationEnable,
                        scheduledTime: dateComponents
                    )
                    try await updatePushSettingsUseCase.execute(settings)
                } catch {
                    send(.setAlert(true))
                    send(.fetchSettings)
                }
            }
        }
    }
}

extension PushNotificationSettingsViewModel {
    func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alertTitle = String(localized: "common_error_title")
        state.alertMessage = String(localized: "common_error_message")
        state.showAlert = isPresented
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
