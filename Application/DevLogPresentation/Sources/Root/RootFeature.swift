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
        @Presents var alert: AlertState<Never>?
        @Presents var sheet: SheetState?
        var isNetworkConnected = true
        var signIn: Bool?
        var theme: SystemTheme = .automatic
        var selectedMainTab = MainTab.home
        var isObservingNetworkConnectivity = false
        var isObservingSession = false
        var isObservingTheme = false
    }

    @ObservableState
    struct SheetState: Equatable, Identifiable {
        let todoId: String
        var id: String { todoId }
    }

    enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Never>)
        case binding(BindingAction<State>)
        case sheet(PresentationAction<Sheet>)
        case view(ViewAction)
        case store(StoreAction)

        enum ViewAction: Equatable {
            case onAppear
            case presentTodoDetail(String)
            case openWidgetRoute(MainTab)
        }

        enum Sheet: Equatable {
            case tapCloseButton
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
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .alert:
                break
            case .binding:
                break
            case .sheet(.dismiss), .sheet(.presented(.tapCloseButton)):
                state.sheet = nil
            case .sheet:
                break
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
            case .view(.presentTodoDetail(let todoId)):
                state.sheet = .init(todoId: todoId)
            case .view(.openWidgetRoute(let mainTab)):
                guard state.signIn == true else { break }
                state.selectedMainTab = mainTab
            case .store(.networkStatusChanged(let isConnected)):
                let wasConnected = state.isNetworkConnected
                state.isNetworkConnected = isConnected
                if wasConnected && !isConnected {
                    state.alert = Self.alertState()
                }
            case .store(.setTheme(let theme)):
                state.theme = theme
            case .store(.didLogined(let result)):
                state.signIn = result
                if result {
                    state.selectedMainTab = .home
                } else {
                    return trackLoginScreenEffect()
                }
            }

            return .none
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$sheet, action: \.sheet) {
            RootSheetFeature()
        }
    }
}

private struct RootSheetFeature: Reducer {
    typealias State = RootFeature.SheetState
    typealias Action = RootFeature.Action.Sheet

    var body: some ReducerOf<Self> {
        EmptyReducer()
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

    static func alertState() -> AlertState<Never> {
        AlertState {
            TextState(String(localized: "root_network_disconnected_title"))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close"))
            }
        } message: {
            TextState(String(localized: "root_network_disconnected_message"))
        }
    }
}
