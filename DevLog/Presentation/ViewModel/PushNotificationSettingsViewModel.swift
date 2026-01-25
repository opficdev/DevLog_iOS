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
    }

    enum SideEffect {
        case fetchPushNotificationSettings
    }

    private let calendar = Calendar.current
    @Published private(set) var state: State = .init()
    private let fetchPushSettingsUseCase: FetchPushSettingsUseCase

    init(fetchPushSettingsUseCase: FetchPushSettingsUseCase) {
        self.fetchPushSettingsUseCase = fetchPushSettingsUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        switch action {
        case .onAppear:
            return [.fetchPushNotificationSettings]
        case .setPushNotificationEnable(let value):
            state.pushNotificationEnable = value
        case .setPushNotificationHour(let value):
            //  시간만 변경
            if let newDate = calendar.date(
                bySettingHour: value,
                minute: calendar.component(.minute, from: state.pushNotificationTime),
                second: 0,
                of: state.pushNotificationTime
            ) {
                state.pushNotificationTime = newDate
            }
        case .setPushNotificationTime(let value):
            state.pushNotificationTime = value
        case .setShowTimePicker(let value):
            state.showTimePicker = value
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
        }
    }
}
