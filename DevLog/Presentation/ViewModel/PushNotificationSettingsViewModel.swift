//
//  PushNotificationSettingsViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 1/18/26.
//

import Foundation

final class PushNotificationSettingsViewModel: Store {
    struct State {
        var pushNotificationEnable: Bool = false
        var pushNotificationTime: Date = .init()
        var showTimePicker: Bool = false
        var isLoading: Bool = false
        var sheetHeight: CGFloat = .pi
        var showSheet: Bool = false
        var showAlert: Bool = false
        var alertTitle: String = ""
        var alertMessage: String = ""
        var pushNotificationHour: Int {
            Calendar.current.component(.hour, from: pushNotificationTime)
        }
        var pushNotificationMinute: Int {
            Calendar.current.component(.minute, from: pushNotificationTime)
        }
    }

    enum Action {
        case onAppear
        case setAlert(Bool)
        case setLoading(Bool)
        case setPushNotificationEnable(Bool)
        case setPushNotificationHour(Int)
        case setPushNotificationTime(Date)
        case setShowTimePicker(Bool)
        case setSheetHeight(CGFloat)
    }

    enum SideEffect {
        case fetchPushNotificationSettings
        case updatePushNotificationSettings
    }

    private let calendar = Calendar.current
    @Published private(set) var state: State = .init()
    private let fetchPushSettingsUseCase: FetchPushSettingsUseCase
    private let updatePushSettingsUseCase: UpdatePushSettingsUseCase

    init(
        fetchPushSettingsUseCase: FetchPushSettingsUseCase,
        updatePushSettingsUseCase: UpdatePushSettingsUseCase
    ) {
        self.fetchPushSettingsUseCase = fetchPushSettingsUseCase
        self.updatePushSettingsUseCase = updatePushSettingsUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        switch action {
        case .onAppear:
            return [.fetchPushNotificationSettings]
        case .setAlert(let isPresented):
            setAlert(&state, isPresented: isPresented)
        case .setLoading(let value):
            state.isLoading = value
        case .setPushNotificationEnable(let value):
            self.state.pushNotificationEnable = value
            return [.updatePushNotificationSettings]
        case .setPushNotificationHour(let value):
            //  시간만 변경
            if let newDate = calendar.date(
                bySettingHour: value,
                minute: 0, second: 0,
                of: state.pushNotificationTime
            ) {
                self.state.pushNotificationTime = newDate
                return [.updatePushNotificationSettings]
            }
        case .setPushNotificationTime(let value):
            self.state.pushNotificationTime = value
            return [.updatePushNotificationSettings]
        case .setShowTimePicker(let value):
            state.showTimePicker = value
        case .setSheetHeight(let value):
            state.sheetHeight = value
        }
        self.state = state
        return []
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetchPushNotificationSettings:
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    let settings = try await fetchPushSettingsUseCase.execute()
                    self.send(.setPushNotificationEnable(settings.isEnabled))
                    if let hour = settings.scheduledTime.hour,
                       let minute = settings.scheduledTime.minute,
                       let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) {
                        self.send(.setPushNotificationTime(date))
                    }
                } catch {
                    send(.setAlert(true))
                }
            }
        case .updatePushNotificationSettings:
            Task {
                do {
                    defer { send(.setLoading(false)) }
                    send(.setLoading(true))
                    let dateComponents = calendar.dateComponents([.hour, .minute], from: state.pushNotificationTime)
                    let settings = PushNotificationSettings(
                        isEnabled: state.pushNotificationEnable,
                        scheduledTime: dateComponents
                    )
                    try await updatePushSettingsUseCase.execute(settings)
                } catch {
                    send(.setAlert(true))
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
        state.alertTitle = "오류"
        state.alertMessage = "문제가 발생했습니다. 잠시 후 다시 시도해주세요."
        state.showAlert = isPresented
    }
}
