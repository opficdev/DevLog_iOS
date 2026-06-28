//
//  WidgetSessionSyncHandlerTests.swift
//  DevLogWidgetTests
//
//  Created by opfic on 6/1/26.
//

import Combine
import Foundation
import Testing
import DevLogData
@testable import DevLogWidget

struct WidgetSessionSyncHandlerTests {
    @Test("로그인 세션 true 첫 진입에서만 위젯 초기 동기화를 요청한다")
    func 로그인_세션_true_첫_진입에서만_위젯_초기_동기화를_요청한다() async {
        let provider = AuthSessionStateProviderSpy()
        let widgetSyncEventBusSpy = WidgetSyncEventBusSpy()
        let widgetSessionSyncHandler = WidgetSessionSyncHandler(
            provider: provider,
            widgetSyncEventBus: widgetSyncEventBusSpy
        )

        provider.publish(true)
        provider.publish(true)

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
        let provider = AuthSessionStateProviderSpy()
        let widgetSyncEventBusSpy = WidgetSyncEventBusSpy()
        let widgetSessionSyncHandler = WidgetSessionSyncHandler(
            provider: provider,
            widgetSyncEventBus: widgetSyncEventBusSpy
        )

        provider.publish(true)
        provider.publish(false)
        provider.publish(true)

        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
        #expect(widgetSyncEventBusSpy.events == [.syncRequested, .syncRequested])
        _ = widgetSessionSyncHandler
    }
}

private final class AuthSessionStateProviderSpy: AuthSessionStateProvider {
    private let subject = PassthroughSubject<Bool, Never>()

    func observeSignedIn() -> AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    func publish(_ isSignedIn: Bool) {
        subject.send(isSignedIn)
    }
}

private final class WidgetSyncEventBusSpy: WidgetSyncEventBus {
    private(set) var events = [WidgetSyncEvent]()

    func publish(_ event: WidgetSyncEvent) {
        events.append(event)
    }

    func request() { }

    func confirmRequest() -> Bool {
        false
    }

    func observe() -> AnyPublisher<WidgetSyncEvent, Never> {
        Empty().eraseToAnyPublisher()
    }
}
