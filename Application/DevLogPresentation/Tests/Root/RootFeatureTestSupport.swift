//
//  RootFeatureTestSupport.swift
//  DevLogPresentationTests
//
//  Created by opfic on 6/17/26.
//

import Combine
import ComposableArchitecture
import DevLogCore
import DevLogDomain
import Testing
@testable import DevLogPresentation

@MainActor
protocol RootStateDriving {
    var snapshot: RootStateSnapshot { get }

    func onAppear() async
    func setAlert(_ isPresented: Bool) async
    func networkStatusChanged(_ isConnected: Bool) async
    func setTheme(_ theme: SystemTheme) async
    func didLogined(_ signIn: Bool) async
}

struct RootStateSnapshot: Equatable {
    let showAlert: Bool
    let alertTitle: String
    let alertMessage: String
    let isNetworkConnected: Bool
    let signIn: Bool?
    let theme: SystemTheme
}

@MainActor
struct RootStoreTestAdapter: RootStateDriving {
    private let store: TestStoreOf<RootFeature>

    var snapshot: RootStateSnapshot {
        RootStateSnapshot(
            showAlert: store.state.showAlert,
            alertTitle: store.state.alertTitle,
            alertMessage: store.state.alertMessage,
            isNetworkConnected: store.state.isNetworkConnected,
            signIn: store.state.signIn,
            theme: store.state.theme
        )
    }

    init(
        sessionUseCase: ObserveAuthSessionUseCase = ObserveAuthSessionUseCaseSpy(currentValue: true),
        networkConnectivityUseCase: ObserveNetworkConnectivityUseCase = RootObserveNetworkConnectivityUseCaseSpy(
            currentValue: true
        ),
        systemThemeUseCase: ObserveSystemThemeUseCase = RootObserveSystemThemeUseCaseSpy(
            currentValue: .automatic
        ),
        trackAnalyticsEventUseCase: TrackAnalyticsEventUseCase = RootTrackAnalyticsEventUseCaseSpy(),
        badgeCountSpy: RootApplicationBadgeCountSpy = RootApplicationBadgeCountSpy()
    ) {
        store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.observeAuthSessionUseCase = sessionUseCase
            $0.networkConnectivityUseCase = networkConnectivityUseCase
            $0.systemThemeUseCase = systemThemeUseCase
            $0.trackAnalyticsEventUseCase = trackAnalyticsEventUseCase
            $0.setApplicationBadgeCount = { count in
                try await badgeCountSpy.setBadgeCount(count)
            }
        }
        store.exhaustivity = .off(showSkippedAssertions: false)
    }

    func onAppear() async {
        await store.send(.view(.onAppear))
        await drainReceivedActions()
    }

    func setAlert(_ isPresented: Bool) async {
        await store.send(.view(.setAlert(isPresented)))
    }

    func networkStatusChanged(_ isConnected: Bool) async {
        await store.send(.store(.networkStatusChanged(isConnected)))
    }

    func setTheme(_ theme: SystemTheme) async {
        await store.send(.store(.setTheme(theme)))
    }

    func didLogined(_ signIn: Bool) async {
        await store.send(.store(.didLogined(signIn)))
    }

    private func drainReceivedActions() async {
        for _ in 0..<8 {
            await store.skipReceivedActions(strict: false)
        }
    }
}

@MainActor
func verifyNetworkDisconnectedAlert(adapter: some RootStateDriving) async {
    await adapter.networkStatusChanged(false)

    #expect(
        adapter.snapshot
            == RootStateSnapshot(
                showAlert: true,
                alertTitle: String(localized: "root_network_disconnected_title"),
                alertMessage: String(localized: "root_network_disconnected_message"),
                isNetworkConnected: false,
                signIn: nil,
                theme: .automatic
            )
    )
}

@MainActor
func verifySetAlert(adapter: some RootStateDriving) async {
    await adapter.networkStatusChanged(false)
    await adapter.setAlert(false)

    #expect(
        adapter.snapshot
            == RootStateSnapshot(
                showAlert: false,
                alertTitle: String(localized: "root_network_disconnected_title"),
                alertMessage: String(localized: "root_network_disconnected_message"),
                isNetworkConnected: false,
                signIn: nil,
                theme: .automatic
            )
    )
}

@MainActor
func verifyThemeUpdate(adapter: some RootStateDriving) async {
    await adapter.setTheme(.dark)

    #expect(adapter.snapshot.theme == .dark)
    #expect(!adapter.snapshot.showAlert)
}

@MainActor
func verifyDidLoginedFalse(
    adapter: some RootStateDriving,
    trackAnalyticsEventUseCaseSpy: RootTrackAnalyticsEventUseCaseSpy
) async {
    await adapter.didLogined(false)
    await waitUntil {
        trackAnalyticsEventUseCaseSpy.screenNames == ["login"]
    }

    #expect(adapter.snapshot.signIn == false)
    #expect(trackAnalyticsEventUseCaseSpy.screenNames == ["login"])
}

@MainActor
func verifyDidLoginedTrue(
    adapter: some RootStateDriving,
    trackAnalyticsEventUseCaseSpy: RootTrackAnalyticsEventUseCaseSpy
) async {
    await adapter.didLogined(true)

    #expect(adapter.snapshot.signIn == true)
    #expect(trackAnalyticsEventUseCaseSpy.screenNames.isEmpty)
}

@MainActor
func verifyObservedInitialValues(adapter: some RootStateDriving) async {
    await adapter.onAppear()
    await waitUntil {
        let snapshot = adapter.snapshot
        return snapshot.signIn == false
            && !snapshot.isNetworkConnected
            && snapshot.theme == .dark
            && snapshot.showAlert
    }

    #expect(
        adapter.snapshot
            == RootStateSnapshot(
                showAlert: true,
                alertTitle: String(localized: "root_network_disconnected_title"),
                alertMessage: String(localized: "root_network_disconnected_message"),
                isNetworkConnected: false,
                signIn: false,
                theme: .dark
            )
    )
}

final class ObserveAuthSessionUseCaseSpy: ObserveAuthSessionUseCase {
    let subject: CurrentValueSubject<Bool, Never>
    private(set) var observeCallCount = 0

    init(currentValue: Bool) {
        subject = CurrentValueSubject(currentValue)
    }

    func observe() -> AnyPublisher<Bool, Never> {
        observeCallCount += 1
        return subject.eraseToAnyPublisher()
    }
}

final class RootObserveNetworkConnectivityUseCaseSpy: ObserveNetworkConnectivityUseCase {
    let subject: CurrentValueSubject<Bool, Never>
    private(set) var observeCallCount = 0

    init(currentValue: Bool) {
        subject = CurrentValueSubject(currentValue)
    }

    func observe() -> AnyPublisher<Bool, Never> {
        observeCallCount += 1
        return subject.eraseToAnyPublisher()
    }
}

final class RootObserveSystemThemeUseCaseSpy: ObserveSystemThemeUseCase {
    let subject: CurrentValueSubject<SystemTheme, Never>
    private(set) var observeCallCount = 0

    init(currentValue: SystemTheme) {
        subject = CurrentValueSubject(currentValue)
    }

    func observe() -> AnyPublisher<SystemTheme, Never> {
        observeCallCount += 1
        return subject.eraseToAnyPublisher()
    }
}

final class RootTrackAnalyticsEventUseCaseSpy: TrackAnalyticsEventUseCase {
    private var events = [AnalyticsEvent]()

    var screenNames: [String] {
        events.compactMap { event in
            guard case .screenView(let screenName) = event else { return nil }
            return screenName
        }
    }

    func execute(_ event: AnalyticsEvent) {
        events.append(event)
    }
}

final class RootApplicationBadgeCountSpy: @unchecked Sendable {
    private(set) var counts = [Int]()

    func setBadgeCount(_ count: Int) async throws {
        counts.append(count)
    }
}
