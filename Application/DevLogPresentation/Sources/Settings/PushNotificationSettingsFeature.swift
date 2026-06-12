//
//  PushNotificationSettingsFeature.swift
//  DevLogPresentation
//
//  Created by opfic on 6/12/26.
//

import ComposableArchitecture
import DevLogDomain
import Foundation
import SwiftUI

@Reducer
struct PushNotificationSettingsFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Never>?
        @Presents var timePicker: TimePickerState?
        var pushNotificationEnable = false
        var viewPushNotificationTime = Date()
        var loading = LoadingFeature.State()

        var isLoading: Bool {
            loading.isLoading
        }
        var pushNotificationHour: Int {
            Calendar.current.component(.hour, from: viewPushNotificationTime)
        }
        var pushNotificationMinute: Int {
            Calendar.current.component(.minute, from: viewPushNotificationTime)
        }
    }

    @ObservableState
    struct TimePickerState: Equatable {
        var time: Date
        var height: CGFloat = .pi
    }

    enum Action: BindableAction {
        case alert(PresentationAction<Never>)
        case binding(BindingAction<State>)
        case timePicker(PresentationAction<TimePicker>)
        case fetchSettings
        case setAlert
        case tapCustomTime
        case selectPresetTime(Date)
        case loading(LoadingFeature.Action)

        enum TimePicker: BindableAction, Equatable {
            case binding(BindingAction<TimePickerState>)
            case tapCloseButton
            case tapDoneButton
        }
    }

    @Dependency(\.fetchPushSettingsUseCase) var fetchPushSettingsUseCase
    @Dependency(\.updatePushSettingsUseCase) var updatePushSettingsUseCase

    var body: some ReducerOf<Self> {
        Scope(state: \.loading, action: \.loading) {
            LoadingFeature()
        }
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .alert:
                break
            case .binding(\.pushNotificationEnable):
                return updatePushNotificationSettingsEffect(settings: settings(from: state))
            case .binding(\.viewPushNotificationTime):
                let time = state.viewPushNotificationTime
                state.timePicker?.time = time
            case .binding:
                break
            case .timePicker(.dismiss):
                state.timePicker = nil
            case .timePicker(.presented(.tapCloseButton)):
                state.timePicker = nil
            case .timePicker(.presented(.tapDoneButton)):
                guard let time = state.timePicker?.time else { break }
                state.timePicker = nil
                state.viewPushNotificationTime = time
                return updatePushNotificationSettingsEffect(settings: settings(from: state))
            case .timePicker:
                break
            case .fetchSettings:
                return fetchPushNotificationSettingsEffect()
            case .setAlert:
                state.alert = alertState()
            case .tapCustomTime:
                state.timePicker = TimePickerState(time: state.viewPushNotificationTime)
            case .selectPresetTime(let date):
                state.viewPushNotificationTime = date
                state.timePicker?.time = date
                return updatePushNotificationSettingsEffect(settings: settings(from: state))
            case .loading:
                break
            }

            return .none
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$timePicker, action: \.timePicker) {
            TimePickerFeature()
        }
    }
}

private struct TimePickerFeature: Reducer {
    typealias State = PushNotificationSettingsFeature.TimePickerState
    typealias Action = PushNotificationSettingsFeature.Action.TimePicker

    var body: some ReducerOf<Self> {
        BindingReducer()
    }
}

extension DependencyValues {
    var fetchPushSettingsUseCase: FetchPushSettingsUseCase {
        get { self[FetchPushSettingsUseCaseKey.self] }
        set { self[FetchPushSettingsUseCaseKey.self] = newValue }
    }

    var updatePushSettingsUseCase: UpdatePushSettingsUseCase {
        get { self[UpdatePushSettingsUseCaseKey.self] }
        set { self[UpdatePushSettingsUseCaseKey.self] = newValue }
    }
}

private enum FetchPushSettingsUseCaseKey: DependencyKey {
    static var liveValue: FetchPushSettingsUseCase {
        preconditionFailure("FetchPushSettingsUseCase must be provided.")
    }

    static var testValue: FetchPushSettingsUseCase {
        liveValue
    }
}

private enum UpdatePushSettingsUseCaseKey: DependencyKey {
    static var liveValue: UpdatePushSettingsUseCase {
        preconditionFailure("UpdatePushSettingsUseCase must be provided.")
    }

    static var testValue: UpdatePushSettingsUseCase {
        liveValue
    }
}

private extension PushNotificationSettingsFeature {
    func fetchPushNotificationSettingsEffect() -> Effect<Action> {
        .run { [fetchPushSettingsUseCase] send in
            await send(.loading(.begin(target: .default, mode: .delayed)))
            do {
                let settings = try await fetchPushSettingsUseCase.execute()
                await send(.binding(.set(\.pushNotificationEnable, settings.isEnabled)))
                if let hour = settings.scheduledTime.hour,
                   let minute = settings.scheduledTime.minute,
                   let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) {
                    await send(.binding(.set(\.viewPushNotificationTime, date)))
                }
                await send(.loading(.end(target: .default, mode: .delayed)))
            } catch {
                await send(.loading(.end(target: .default, mode: .delayed)))
                await send(.setAlert)
            }
        }
    }

    func updatePushNotificationSettingsEffect(settings: PushNotificationSettings) -> Effect<Action> {
        .run { [updatePushSettingsUseCase] send in
            await send(.loading(.begin(target: .default, mode: .delayed)))
            do {
                try await updatePushSettingsUseCase.execute(settings)
                await send(.loading(.end(target: .default, mode: .delayed)))
            } catch {
                await send(.loading(.end(target: .default, mode: .delayed)))
                await send(.setAlert)
                await send(.fetchSettings)
            }
        }
    }

    func settings(from state: State) -> PushNotificationSettings {
        let date = state.timePicker?.time ?? state.viewPushNotificationTime
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: date)
        return PushNotificationSettings(
            isEnabled: state.pushNotificationEnable,
            scheduledTime: dateComponents
        )
    }

    func alertState() -> AlertState<Never> {
        AlertState {
            TextState(String(localized: "common_error_title"))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close"))
            }
        } message: {
            TextState(String(localized: "common_error_message"))
        }
    }
}
