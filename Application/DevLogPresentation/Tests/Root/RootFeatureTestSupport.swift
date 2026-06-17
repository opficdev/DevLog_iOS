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
    var sheetTodoId: String? { get }

    func onAppear() async
    func setAlert(_ isPresented: Bool) async
    func networkStatusChanged(_ isConnected: Bool) async
    func setTheme(_ theme: SystemTheme) async
    func didLogined(_ signIn: Bool) async
    func presentTodoDetail(_ todoId: String) async
    func dismissSheet() async
    func selectMainTab(_ tab: MainTab) async
    func openWidgetRoute(_ tab: MainTab) async
}

struct RootStateSnapshot: Equatable {
    let alertTitle: String?
    let alertMessage: String?
    let isNetworkConnected: Bool
    let signIn: Bool?
    let theme: SystemTheme
    let selectedMainTab: MainTab
}

@MainActor
struct RootStoreTestAdapter: RootStateDriving {
    private let store: TestStoreOf<RootFeature>

    var snapshot: RootStateSnapshot {
        RootStateSnapshot(
            alertTitle: store.state.alert.map { String(state: $0.title) },
            alertMessage: store.state.alert?.message.map { String(state: $0) },
            isNetworkConnected: store.state.isNetworkConnected,
            signIn: store.state.signIn,
            theme: store.state.theme,
            selectedMainTab: store.state.selectedMainTab
        )
    }
    var sheetTodoId: String? { store.state.sheet?.todoId }

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
        await store.send(.onAppear)
        await drainReceivedActions()
    }

    func setAlert(_ isPresented: Bool) async {
        if isPresented {
            await store.send(.networkStatusChanged(false))
        } else {
            await store.send(.alert(.dismiss))
        }
    }

    func networkStatusChanged(_ isConnected: Bool) async {
        await store.send(.networkStatusChanged(isConnected))
    }

    func setTheme(_ theme: SystemTheme) async {
        await store.send(.setTheme(theme))
    }

    func didLogined(_ signIn: Bool) async {
        await store.send(.didLogined(signIn))
    }

    func presentTodoDetail(_ todoId: String) async {
        await store.send(.presentTodoDetail(todoId))
    }

    func dismissSheet() async {
        await store.send(.sheet(.dismiss))
    }

    func selectMainTab(_ tab: MainTab) async {
        await store.send(.binding(.set(\.selectedMainTab, tab)))
    }

    func openWidgetRoute(_ tab: MainTab) async {
        await store.send(.openWidgetRoute(tab))
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
                alertTitle: String(localized: "root_network_disconnected_title"),
                alertMessage: String(localized: "root_network_disconnected_message"),
                isNetworkConnected: false,
                signIn: nil,
                theme: .automatic,
                selectedMainTab: .home
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
                alertTitle: nil,
                alertMessage: nil,
                isNetworkConnected: false,
                signIn: nil,
                theme: .automatic,
                selectedMainTab: .home
            )
    )
}

@MainActor
func verifyThemeUpdate(adapter: some RootStateDriving) async {
    await adapter.setTheme(.dark)

    #expect(adapter.snapshot.theme == .dark)
    #expect(adapter.snapshot.alertTitle == nil)
    #expect(adapter.snapshot.selectedMainTab == .home)
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
    #expect(adapter.snapshot.selectedMainTab == .home)
    #expect(trackAnalyticsEventUseCaseSpy.screenNames == ["login"])
}

@MainActor
func verifyDidLoginedTrue(
    adapter: some RootStateDriving,
    trackAnalyticsEventUseCaseSpy: RootTrackAnalyticsEventUseCaseSpy
) async {
    await adapter.selectMainTab(.today)
    await adapter.didLogined(true)

    #expect(adapter.snapshot.signIn == true)
    #expect(adapter.snapshot.selectedMainTab == .home)
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
            && snapshot.alertTitle == String(localized: "root_network_disconnected_title")
    }

    #expect(
        adapter.snapshot
            == RootStateSnapshot(
                alertTitle: String(localized: "root_network_disconnected_title"),
                alertMessage: String(localized: "root_network_disconnected_message"),
                isNetworkConnected: false,
                signIn: false,
                theme: .dark,
                selectedMainTab: .home
            )
    )
}

@MainActor
func verifyTodoDetailSheetPresentation(adapter: some RootStateDriving) async {
    await adapter.presentTodoDetail("todo-1")
    #expect(adapter.sheetTodoId == "todo-1")

    await adapter.dismissSheet()
    #expect(adapter.sheetTodoId == nil)
}

@MainActor
func verifyWidgetRouteOpensWhenSignedIn(adapter: some RootStateDriving) async {
    await adapter.openWidgetRoute(.today)
    #expect(adapter.snapshot.selectedMainTab == .home)

    await adapter.didLogined(true)
    await adapter.openWidgetRoute(.today)
    #expect(adapter.snapshot.selectedMainTab == .today)
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
