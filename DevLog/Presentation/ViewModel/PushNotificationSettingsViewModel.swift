//
//  PushNotificationSettingsViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 1/18/26.
//

import Foundation

final class PushNotificationSettingsViewModel: Store {
    struct State {
        var pushNotificationEnable = false
        var pushNotificationTime = Date()
        var showTimePicker = false
        var sheetHeight = CGFloat.pi
        var pushNotificationHour: Int {
            Calendar.current.component(.hour, from: pushNotificationTime)
        }
    }

    enum Action {
        case onAppear
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
                let settings = try await fetchPushSettingsUseCase.execute()
                self.send(.setPushNotificationEnable(settings.isEnabled))
                if let hour = settings.scheduledTime.hour,
                   let minute = settings.scheduledTime.minute,
                   let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) {
                    self.send(.setPushNotificationTime(date))
                }
            }
        case .updatePushNotificationSettings:
            Task {
                let dateComponents = calendar.dateComponents([.hour, .minute], from: state.pushNotificationTime)
                let settings = PushNotificationSettings(
                    isEnabled: state.pushNotificationEnable,
                    scheduledTime: dateComponents
                )

                try await updatePushSettingsUseCase.execute(settings)
            }
        }
    }
}
