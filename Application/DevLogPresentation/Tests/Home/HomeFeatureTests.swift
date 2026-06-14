//
//  HomeFeatureTests.swift
//  DevLogPresentationTests
//
//  Created by opfic on 6/14/26.
//

import Testing
import Foundation
import DevLogDomain
@testable import DevLogPresentation

@MainActor
struct HomeFeatureTests {
    @Test("현재 HomeViewModel fetchData는 preferences, recentTodos, webPages를 갱신한다")
    func 현재_HomeViewModel_fetchData는_preferences_recentTodos_webPages를_갱신한다() async throws {
        let context = makeHomeFetchDataContext()
        let adapter = HomeViewModelTestAdapter(
            fetchPreferencesUseCase: context.fetchPreferencesUseCaseSpy,
            fetchTodosUseCase: context.fetchTodosUseCaseSpy,
            fetchWebPagesUseCase: context.fetchWebPagesUseCaseSpy
        )

        try await verifyHomeFetchData(
            adapter: adapter,
            fetchTodosUseCaseSpy: context.fetchTodosUseCaseSpy,
            fetchWebPagesUseCaseSpy: context.fetchWebPagesUseCaseSpy
        )
    }

    @Test("HomeFeature fetchData는 현재 HomeViewModel과 같은 홈 상태를 만든다")
    func HomeFeature_fetchData는_현재_HomeViewModel과_같은_홈_상태를_만든다() async throws {
        let context = makeHomeFetchDataContext()
        let adapter = HomeStoreTestAdapter(
            fetchPreferencesUseCase: context.fetchPreferencesUseCaseSpy,
            fetchTodosUseCase: context.fetchTodosUseCaseSpy,
            fetchWebPagesUseCase: context.fetchWebPagesUseCaseSpy
        )

        try await verifyHomeFetchData(
            adapter: adapter,
            fetchTodosUseCaseSpy: context.fetchTodosUseCaseSpy,
            fetchWebPagesUseCaseSpy: context.fetchWebPagesUseCaseSpy
        )
    }

    @Test("현재 HomeViewModel setAlert(webPageInput)는 contentPicker를 닫고 alert를 지연 표시한다")
    func 현재_HomeViewModel_setAlert_webPageInput는_contentPicker를_닫고_alert를_지연_표시한다() async throws {
        let adapter = HomeViewModelTestAdapter()

        try await verifyHomeWebPageInputAlert(adapter: adapter)
    }

    @Test("HomeFeature setAlert(webPageInput)는 현재 HomeViewModel과 같은 지연 표시를 유지한다")
    func HomeFeature_setAlert_webPageInput는_현재_HomeViewModel과_같은_지연_표시를_유지한다() async throws {
        let adapter = HomeStoreTestAdapter()

        try await verifyHomeWebPageInputAlert(adapter: adapter)
    }

    @Test("현재 HomeViewModel tapTodoCategory는 category를 선택하고 editor를 지연 표시한다")
    func 현재_HomeViewModel_tapTodoCategory는_category를_선택하고_editor를_지연_표시한다() async throws {
        let adapter = HomeViewModelTestAdapter()

        try await verifyHomeTapTodoCategory(adapter: adapter)
    }

    @Test("HomeFeature tapTodoCategory는 현재 HomeViewModel과 같은 editor 표시를 유지한다")
    func HomeFeature_tapTodoCategory는_현재_HomeViewModel과_같은_editor_표시를_유지한다() async throws {
        let adapter = HomeStoreTestAdapter()

        try await verifyHomeTapTodoCategory(adapter: adapter)
    }

    @Test("현재 HomeViewModel orderTodoCategory는 recentTodos category를 동기화하고 저장한다")
    func 현재_HomeViewModel_orderTodoCategory는_recentTodos_category를_동기화하고_저장한다() async throws {
        let context = makeHomeOrderContext()
        let adapter = HomeViewModelTestAdapter(
            fetchPreferencesUseCase: context.fetchPreferencesUseCaseSpy,
            updatePreferencesUseCase: context.updatePreferencesUseCaseSpy,
            fetchTodosUseCase: context.fetchTodosUseCaseSpy
        )

        try await verifyHomeOrderTodoCategory(
            adapter: adapter,
            updatePreferencesUseCaseSpy: context.updatePreferencesUseCaseSpy
        )
    }

    @Test("HomeFeature orderTodoCategory는 현재 HomeViewModel과 같은 recentTodos 동기화를 유지한다")
    func HomeFeature_orderTodoCategory는_현재_HomeViewModel과_같은_recentTodos_동기화를_유지한다() async throws {
        let context = makeHomeOrderContext()
        let adapter = HomeStoreTestAdapter(
            fetchPreferencesUseCase: context.fetchPreferencesUseCaseSpy,
            updatePreferencesUseCase: context.updatePreferencesUseCaseSpy,
            fetchTodosUseCase: context.fetchTodosUseCaseSpy
        )

        try await verifyHomeOrderTodoCategory(
            adapter: adapter,
            updatePreferencesUseCaseSpy: context.updatePreferencesUseCaseSpy
        )
    }

    @Test("현재 HomeViewModel addWebPage는 URL을 정규화하고 목록을 다시 불러온다")
    func 현재_HomeViewModel_addWebPage는_URL을_정규화하고_목록을_다시_불러온다() async throws {
        let context = makeHomeAddWebPageContext()
        let adapter = HomeViewModelTestAdapter(
            addWebPageUseCase: context.addWebPageUseCaseSpy,
            fetchWebPagesUseCase: context.fetchWebPagesUseCaseSpy,
            trackAnalyticsEventUseCase: context.trackAnalyticsEventUseCaseSpy
        )

        try await verifyHomeAddWebPage(
            adapter: adapter,
            addWebPageUseCaseSpy: context.addWebPageUseCaseSpy,
            fetchWebPagesUseCaseSpy: context.fetchWebPagesUseCaseSpy,
            trackAnalyticsEventUseCaseSpy: context.trackAnalyticsEventUseCaseSpy
        )
    }

    @Test("HomeFeature addWebPage는 현재 HomeViewModel과 같은 URL 정규화와 목록 갱신을 유지한다")
    func HomeFeature_addWebPage는_현재_HomeViewModel과_같은_URL_정규화와_목록_갱신을_유지한다() async throws {
        let context = makeHomeAddWebPageContext()
        let adapter = HomeStoreTestAdapter(
            addWebPageUseCase: context.addWebPageUseCaseSpy,
            fetchWebPagesUseCase: context.fetchWebPagesUseCaseSpy,
            trackAnalyticsEventUseCase: context.trackAnalyticsEventUseCaseSpy
        )

        try await verifyHomeAddWebPage(
            adapter: adapter,
            addWebPageUseCaseSpy: context.addWebPageUseCaseSpy,
            fetchWebPagesUseCaseSpy: context.fetchWebPagesUseCaseSpy,
            trackAnalyticsEventUseCaseSpy: context.trackAnalyticsEventUseCaseSpy
        )
    }

    @Test("현재 HomeViewModel delete와 undoDeleteWebPage는 숨김 상태와 복구를 제어한다")
    func 현재_HomeViewModel_delete와_undoDeleteWebPage는_숨김_상태와_복구를_제어한다() async throws {
        let context = makeHomeDeleteContext()
        let adapter = HomeViewModelTestAdapter(
            fetchWebPagesUseCase: context.fetchWebPagesUseCaseSpy,
            deleteWebPageUseCase: context.deleteWebPageUseCaseSpy,
            undoDeleteWebPageUseCase: context.undoDeleteWebPageUseCaseSpy,
            addWebPageUseCase: context.addWebPageUseCaseSpy
        )

        try await verifyHomeDeleteUndoWebPage(
            adapter: adapter,
            deleteWebPageUseCaseSpy: context.deleteWebPageUseCaseSpy,
            undoDeleteWebPageUseCaseSpy: context.undoDeleteWebPageUseCaseSpy
        )
    }

    @Test("HomeFeature delete와 undoDeleteWebPage는 현재 HomeViewModel과 같은 숨김 상태를 유지한다")
    func HomeFeature_delete와_undoDeleteWebPage는_현재_HomeViewModel과_같은_숨김_상태를_유지한다() async throws {
        let context = makeHomeDeleteContext()
        let adapter = HomeStoreTestAdapter(
            fetchWebPagesUseCase: context.fetchWebPagesUseCaseSpy,
            deleteWebPageUseCase: context.deleteWebPageUseCaseSpy,
            undoDeleteWebPageUseCase: context.undoDeleteWebPageUseCaseSpy,
            addWebPageUseCase: context.addWebPageUseCaseSpy
        )

        try await verifyHomeDeleteUndoWebPage(
            adapter: adapter,
            deleteWebPageUseCaseSpy: context.deleteWebPageUseCaseSpy,
            undoDeleteWebPageUseCaseSpy: context.undoDeleteWebPageUseCaseSpy
        )
    }

    @Test("HomeFeature startObserving은 네트워크 연결 상태를 반영한다")
    func HomeFeature_startObserving은_네트워크_연결_상태를_반영한다() async {
        let networkUseCaseSpy = ObserveNetworkConnectivityUseCaseSpy()
        let adapter = HomeStoreTestAdapter(networkConnectivityUseCase: networkUseCaseSpy)

        await adapter.startObserving()

        #expect(adapter.isNetworkConnected)

        networkUseCaseSpy.currentValueSubject.send(false)

        await waitUntil {
            adapter.isNetworkConnected == false
        }

        #expect(!adapter.isNetworkConnected)
    }
}
