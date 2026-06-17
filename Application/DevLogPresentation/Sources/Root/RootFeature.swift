//
//  RootFeature.swift
//  DevLogPresentation
//
//  Created by opfic on 6/17/26.
//

import Combine
import ComposableArchitecture
import DevLogCore
import DevLogDomain
import Foundation

@Reducer
struct RootFeature {
    private enum CancelID: Hashable {
        case networkConnectivity
        case session
        case theme
    }

    @ObservableState
    struct State: Equatable {
        var showAlert = false
        var alertTitle = ""
        var alertMessage = ""
        var isNetworkConnected = true
        var signIn: Bool?
        var theme: SystemTheme = .automatic
        var isObservingNetworkConnectivity = false
        var isObservingSession = false
        var isObservingTheme = false
    }

    enum Action: Equatable {
        case view(ViewAction)
        case store(StoreAction)

        enum ViewAction: Equatable {
            case onAppear
            case setAlert(Bool)
        }

        enum StoreAction: Equatable {
            case networkStatusChanged(Bool)
            case setTheme(SystemTheme)
            case didLogined(Bool)
        }
    }

    @Dependency(\.observeAuthSessionUseCase) var observeAuthSessionUseCase
    @Dependency(\.networkConnectivityUseCase) var networkConnectivityUseCase
    @Dependency(\.systemThemeUseCase) var systemThemeUseCase
    @Dependency(\.trackAnalyticsEventUseCase) var trackAnalyticsEventUseCase
    @Dependency(\.setApplicationBadgeCount) var setApplicationBadgeCount

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.onAppear):
                var effect = clearApplicationBadgeCountEffect()

                if !state.isObservingNetworkConnectivity {
                    state.isObservingNetworkConnectivity = true
                    effect = .merge(effect, observeNetworkConnectivityEffect())
                }

                if !state.isObservingSession {
                    state.isObservingSession = true
                    effect = .merge(effect, observeSessionEffect())
                }

                if !state.isObservingTheme {
                    state.isObservingTheme = true
                    effect = .merge(effect, observeThemeEffect())
                }

                return effect
            case .view(.setAlert(let isPresented)):
                Self.setAlert(&state, isPresented: isPresented)
            case .store(.networkStatusChanged(let isConnected)):
                let wasConnected = state.isNetworkConnected
                state.isNetworkConnected = isConnected
                if wasConnected && !isConnected {
                    Self.setAlert(&state, isPresented: true)
                }
            case .store(.setTheme(let theme)):
                state.theme = theme
            case .store(.didLogined(let result)):
                state.signIn = result
                if !result {
                    return trackLoginScreenEffect()
                }
            }

            return .none
        }
    }
}

extension DependencyValues {
    var observeAuthSessionUseCase: ObserveAuthSessionUseCase {
        get { self[ObserveAuthSessionUseCaseKey.self] }
        set { self[ObserveAuthSessionUseCaseKey.self] = newValue }
    }
}

private enum ObserveAuthSessionUseCaseKey: DependencyKey {
    static var liveValue: ObserveAuthSessionUseCase {
        preconditionFailure("ObserveAuthSessionUseCase must be provided.")
    }

    static var testValue: ObserveAuthSessionUseCase {
        liveValue
    }
}

private extension RootFeature {
    func clearApplicationBadgeCountEffect() -> Effect<Action> {
        .run { [setApplicationBadgeCount] _ in
            try? await setApplicationBadgeCount(0)
        }
    }

    func observeNetworkConnectivityEffect() -> Effect<Action> {
        .publisher { [networkConnectivityUseCase] in
            networkConnectivityUseCase.observe()
                .map { Action.store(.networkStatusChanged($0)) }
        }
        .cancellable(id: CancelID.networkConnectivity, cancelInFlight: true)
    }

    func observeSessionEffect() -> Effect<Action> {
        .publisher { [observeAuthSessionUseCase] in
            observeAuthSessionUseCase.observe()
                .removeDuplicates()
                .map { Action.store(.didLogined($0)) }
        }
        .cancellable(id: CancelID.session, cancelInFlight: true)
    }

    func observeThemeEffect() -> Effect<Action> {
        .publisher { [systemThemeUseCase] in
            systemThemeUseCase.observe()
                .removeDuplicates()
                .map { Action.store(.setTheme($0)) }
        }
        .cancellable(id: CancelID.theme, cancelInFlight: true)
    }

    func trackLoginScreenEffect() -> Effect<Action> {
        .run { [trackAnalyticsEventUseCase] _ in
            trackAnalyticsEventUseCase?.execute(.screenView("login"))
        }
    }

    static func setAlert(_ state: inout State, isPresented: Bool) {
        state.alertTitle = String(localized: "root_network_disconnected_title")
        state.alertMessage = String(localized: "root_network_disconnected_message")
        state.showAlert = isPresented
    }
}
