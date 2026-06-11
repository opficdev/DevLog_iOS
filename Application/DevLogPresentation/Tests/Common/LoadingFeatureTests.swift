//
//  LoadingFeatureTests.swift
//  DevLogPresentationTests
//
//  Created by opfic on 6/11/26.
//

import Testing
import ComposableArchitecture
@testable import DevLogPresentation

@MainActor
struct LoadingFeatureTests {
    @Test("즉시 로딩은 시작하면 표시되고 종료하면 해제된다")
    func 즉시_로딩은_시작하면_표시되고_종료하면_해제된다() async {
        let target = LoadingFeature.Target.default
        let store = TestStore(initialState: LoadingFeature.State()) {
            LoadingFeature()
        }

        await store.send(.begin(target: target, mode: .immediate)) {
            $0.immediateCountByTarget[target] = 1
            $0.visibleTargets = [target]
            $0.isLoading = true
        }

        await store.send(.end(target: target, mode: .immediate)) {
            $0.immediateCountByTarget[target] = 0
            $0.visibleTargets = []
            $0.isLoading = false
        }
    }

    @Test("지연 로딩은 delay가 지나기 전까지 표시되지 않는다")
    func 지연_로딩은_delay가_지나기_전까지_표시되지_않는다() async {
        let target = LoadingFeature.Target.default
        let clock = TestClock()
        let store = TestStore(initialState: LoadingFeature.State()) {
            LoadingFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.begin(target: target, mode: .delayed)) {
            $0.delayedCountByTarget[target] = 1
            $0.scheduledDelayedTargets = [target]
        }

        await clock.advance(by: .milliseconds(299))

        await clock.advance(by: .milliseconds(1))
        await store.receive(.delayedLoadingDidBecomeVisible(target: target)) {
            $0.scheduledDelayedTargets = []
            $0.visibleDelayedTargets = [target]
            $0.visibleTargets = [target]
            $0.isLoading = true
        }

        await store.send(.end(target: target, mode: .delayed)) {
            $0.delayedCountByTarget[target] = 0
            $0.visibleDelayedTargets = []
            $0.visibleTargets = []
            $0.isLoading = false
        }
    }
}
