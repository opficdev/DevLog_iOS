//
//  WidgetSessionSyncHandlerTests.swift
//  DevLogAppTests
//
//  Created by opfic on 6/1/26.
//

import Combine
import Foundation
import Testing
import DevLogData
@testable import DevLog

struct WidgetSessionSyncHandlerTests {
    @Test("로그인 세션 true 첫 진입에서만 위젯 초기 동기화를 요청한다")
    func 로그인_세션_true_첫_진입에서만_위젯_초기_동기화를_요청한다() async {
        let authServiceSpy = AuthServiceSpy()
        let widgetSyncEventBusSpy = WidgetSyncEventBusSpy()
        let widgetSessionSyncHandler = WidgetSessionSyncHandler(
            authService: authServiceSpy,
            widgetSyncEventBus: widgetSyncEventBusSpy
        )

        authServiceSpy.send(true)
        authServiceSpy.send(true)

        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
        #expect(widgetSyncEventBusSpy.events == [.syncRequested])
        _ = widgetSessionSyncHandler
    }

    @Test("로그아웃 이후 재로그인 시 위젯 초기 동기화를 다시 요청한다")
    func 로그아웃_이후_재로그인_시_위젯_초기_동기화를_다시_요청한다() async {
        let authServiceSpy = AuthServiceSpy()
        let widgetSyncEventBusSpy = WidgetSyncEventBusSpy()
        let widgetSessionSyncHandler = WidgetSessionSyncHandler(
            authService: authServiceSpy,
            widgetSyncEventBus: widgetSyncEventBusSpy
        )

        authServiceSpy.send(true)
        authServiceSpy.send(false)
        authServiceSpy.send(true)

        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
        #expect(widgetSyncEventBusSpy.events == [.syncRequested, .syncRequested])
        _ = widgetSessionSyncHandler
    }
}

private final class AuthServiceSpy: AuthService {
    private let currentValueSubject = CurrentValueSubject<Bool, Never>(false)

    var uid: String? { nil }
    var providerIDs: [String] { [] }
    var currentUserEmail: String? { nil }
    var providerCount: Int { 0 }

    func observeSignedIn() -> AnyPublisher<Bool, Never> {
        currentValueSubject.eraseToAnyPublisher()
    }

    func beginSignIn() { }
    func completeSignIn() { }
    func cancelSignIn() { }
    func getProviderID() async throws -> String? { nil }
    func deleteCurrentUser() async throws { }
    func clearCurrentSession() async throws { }

    func send(_ isSignedIn: Bool) {
        currentValueSubject.send(isSignedIn)
    }
}

private final class WidgetSyncEventBusSpy: WidgetSyncEventBus {
    private(set) var events = [WidgetSyncEvent]()

    func publish(_ event: WidgetSyncEvent) {
        events.append(event)
    }

    func observe() -> AnyPublisher<WidgetSyncEvent, Never> {
        Empty().eraseToAnyPublisher()
    }
}
