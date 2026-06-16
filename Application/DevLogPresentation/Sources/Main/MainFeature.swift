//
//  MainFeature.swift
//  DevLogPresentation
//
//  Created by opfic on 6/16/26.
//

import Combine
import ComposableArchitecture
import DevLogCore
import DevLogDomain
import Foundation
import UserNotifications

@Reducer
struct MainFeature {
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Never>?
        var unreadPushCount = 0
        var isObservingUnreadPushCount = false
    }

    enum Action: Equatable {
        case alert(PresentationAction<Never>)
        case view(ViewAction)
        case store(StoreAction)

        enum ViewAction: Equatable {
            case onAppear
            case selectedTabChanged(MainTab)
        }

        enum StoreAction: Equatable {
            case setUnreadPushCount(Int)
            case setAlert(Bool)
        }
    }

    private enum CancelID: Hashable {
        case unreadPushCount
    }

    @Dependency(\.observeUnreadPushCountUseCase) var observeUnreadPushCountUseCase
    @Dependency(\.trackAnalyticsEventUseCase) var trackAnalyticsEventUseCase
    @Dependency(\.setApplicationBadgeCount) var setApplicationBadgeCount

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert:
                break
            case .view(.onAppear):
                guard !state.isObservingUnreadPushCount else { break }
                state.isObservingUnreadPushCount = true
                return observeUnreadPushCountEffect()
            case .view(.selectedTabChanged(let tab)):
                guard tab.analyticsScreenName != nil else { break }
                return trackScreenViewEffect(tab)
            case .store(.setUnreadPushCount(let count)):
                state.unreadPushCount = count
                return updateBadgeCountEffect(count)
            case .store(.setAlert(let isPresented)):
                Self.setAlert(&state, isPresented: isPresented)
            }

            return .none
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension DependencyValues {
    var observeUnreadPushCountUseCase: ObserveUnreadPushCountUseCase {
        get { self[ObserveUnreadPushCountUseCaseKey.self] }
        set { self[ObserveUnreadPushCountUseCaseKey.self] = newValue }
    }

    var setApplicationBadgeCount: @Sendable (Int) async throws -> Void {
        get { self[SetApplicationBadgeCountKey.self] }
        set { self[SetApplicationBadgeCountKey.self] = newValue }
    }
}

private enum ObserveUnreadPushCountUseCaseKey: DependencyKey {
    static var liveValue: ObserveUnreadPushCountUseCase {
        preconditionFailure("ObserveUnreadPushCountUseCase must be provided.")
    }

    static var testValue: ObserveUnreadPushCountUseCase {
        liveValue
    }
}

private enum SetApplicationBadgeCountKey: DependencyKey {
    static let liveValue: @Sendable (Int) async throws -> Void = { count in
        try await withCheckedThrowingContinuation { continuation in
            UNUserNotificationCenter.current().setBadgeCount(count) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    static var testValue: @Sendable (Int) async throws -> Void {
        liveValue
    }
}

private extension MainFeature {
    func observeUnreadPushCountEffect() -> Effect<Action> {
        .run { [observeUnreadPushCountUseCase] send in
            do {
                let publisher = try observeUnreadPushCountUseCase.observe()
                    .receive(on: DispatchQueue.main)
                for try await count in publisher.values {
                    await send(.store(.setUnreadPushCount(count)))
                }
            } catch {
                await send(.store(.setAlert(true)))
            }
        }
        .cancellable(id: CancelID.unreadPushCount, cancelInFlight: true)
    }

    func trackScreenViewEffect(_ tab: MainTab) -> Effect<Action> {
        .run { [trackAnalyticsEventUseCase] _ in
            guard let screenName = tab.analyticsScreenName else { return }
            trackAnalyticsEventUseCase?.execute(.screenView(screenName))
        }
    }

    func updateBadgeCountEffect(_ count: Int) -> Effect<Action> {
        .run { [setApplicationBadgeCount] _ in
            do {
                try await setApplicationBadgeCount(count)
            } catch {
                Logger(category: "MainFeature").error("Failed to update application badge count", error: error)
            }
        }
    }

    static func setAlert(
        _ state: inout State,
        isPresented: Bool
    ) {
        state.alert = isPresented ? alertState() : nil
    }

    static func alertState() -> AlertState<Never> {
        AlertState {
            TextState(String(localized: "common_error_title"))
        } actions: {
            ButtonState(role: .cancel) {
                TextState(String(localized: "common_close"))
            }
        } message: {
            TextState(String(localized: "main_alert_badge_error_message"))
        }
    }
}

private extension MainTab {
    var analyticsScreenName: String? {
        switch self {
        case .home:
            return "home"
        case .today:
            return "today"
        case .notification:
            return nil
        case .profile:
            return "profile"
        }
    }
}
