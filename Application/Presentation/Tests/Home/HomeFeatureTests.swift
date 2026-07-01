//
//  HomeFeatureTests.swift
//  PresentationTests
//
//  Created by opfic on 6/14/26.
//

import Testing
import Foundation
import Domain
@testable import Presentation

@MainActor
struct HomeFeatureTests {
    @Test("HomeFeature fetchData는 홈 상태를 갱신한다")
    func HomeFeature_fetchData는_홈_상태를_갱신한다() async throws {
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

    @Test("HomeFeature webPageInput은 contentPicker 내부 내비게이션을 표시한다")
    func HomeFeature_webPageInput은_contentPicker_내부_내비게이션을_표시한다() async throws {
        let adapter = HomeStoreTestAdapter()

        try await verifyHomeWebPageInputAlert(adapter: adapter)
    }

    @Test("HomeFeature tapTodoCategory는 editor를 지연 표시한다")
    func HomeFeature_tapTodoCategory는_editor를_지연_표시한다() async throws {
        let adapter = HomeStoreTestAdapter()

        try await verifyHomeTapTodoCategory(adapter: adapter)
    }

    @Test("TodoEditor 생성 delegate는 editor를 닫고 홈 데이터를 다시 조회한다")
    func TodoEditor_생성_delegate는_editor를_닫고_홈_데이터를_다시_조회한다() async throws {
        let context = makeHomeFetchDataContext()
        let adapter = HomeStoreTestAdapter(
            fetchPreferencesUseCase: context.fetchPreferencesUseCaseSpy,
            fetchTodosUseCase: context.fetchTodosUseCaseSpy,
            fetchWebPagesUseCase: context.fetchWebPagesUseCaseSpy
        )

        await adapter.tapTodoCategory(.system(.feature))
        await adapter.todoEditorCreated()

        await waitUntil {
            context.fetchTodosUseCaseSpy.queries.count == 1
                && context.fetchWebPagesUseCaseSpy.calledQueries == [""]
        }

        #expect(!adapter.showTodoEditor)
        #expect(adapter.recentTodos.map(\.id) == ["todo-1", "todo-2"])
        #expect(adapter.webPages.map(\.url.absoluteString) == ["https://openai.com"])
    }

    @Test("HomeFeature orderTodoCategory는 recentTodos category를 동기화하고 저장한다")
    func HomeFeature_orderTodoCategory는_recentTodos_category를_동기화하고_저장한다() async throws {
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

    @Test("HomeFeature addWebPage는 URL을 정규화하고 목록을 다시 불러온다")
    func HomeFeature_addWebPage는_URL을_정규화하고_목록을_다시_불러온다() async throws {
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

    @Test("HomeFeature addWebPage 실패는 입력 시트를 유지한다")
    func HomeFeature_addWebPage_실패는_입력_시트를_유지한다() async throws {
        let context = makeHomeAddWebPageContext()
        context.addWebPageUseCaseSpy.error = HomeTestError.failure
        let adapter = HomeStoreTestAdapter(
            addWebPageUseCase: context.addWebPageUseCaseSpy,
            fetchWebPagesUseCase: context.fetchWebPagesUseCaseSpy,
            trackAnalyticsEventUseCase: context.trackAnalyticsEventUseCaseSpy
        )

        try await verifyHomeAddWebPageFailureKeepsSheet(
            adapter: adapter,
            addWebPageUseCaseSpy: context.addWebPageUseCaseSpy
        )
    }

    @Test("웹페이지를 삭제하면 항목이 즉시 숨겨지고 삭제 유스케이스가 호출된다")
    func 웹페이지를_삭제하면_항목이_즉시_숨겨지고_삭제_유스케이스가_호출된다() async throws {
        let context = makeHomeDeleteContext()
        let adapter = HomeStoreTestAdapter(
            addWebPageUseCase: context.addWebPageUseCaseSpy,
            deleteWebPageUseCase: context.deleteWebPageUseCaseSpy,
            undoDeleteWebPageUseCase: context.undoDeleteWebPageUseCaseSpy,
            fetchWebPagesUseCase: context.fetchWebPagesUseCaseSpy,
        )

        await adapter.fetchData()

        let webPageItem = try #require(adapter.webPages.first)

        await adapter.deleteWebPage(webPageItem)

        #expect(adapter.webPages.filter { !$0.isHidden }.isEmpty)

        await waitUntil {
            context.deleteWebPageUseCaseSpy.calls.count == 1
        }

        #expect(context.deleteWebPageUseCaseSpy.calls.first?.id == "web-page-id")
        #expect(context.deleteWebPageUseCaseSpy.calls.first?.urlString == "https://openai.com")
    }

    @Test("웹페이지 삭제를 되돌리면 되돌리기 유스케이스가 호출되고 숨김 상태가 해제된다")
    func 웹페이지_삭제를_되돌리면_되돌리기_유스케이스가_호출되고_숨김_상태가_해제된다() async throws {
        let context = makeHomeDeleteContext()
        let adapter = HomeStoreTestAdapter(
            addWebPageUseCase: context.addWebPageUseCaseSpy,
            deleteWebPageUseCase: context.deleteWebPageUseCaseSpy,
            undoDeleteWebPageUseCase: context.undoDeleteWebPageUseCaseSpy,
            fetchWebPagesUseCase: context.fetchWebPagesUseCaseSpy,
        )

        await adapter.fetchData()

        let webPageItem = try #require(adapter.webPages.first)

        await adapter.deleteWebPage(webPageItem)
        await adapter.undoDeleteWebPage()

        await waitUntil {
            context.undoDeleteWebPageUseCaseSpy.calledIDs == ["web-page-id"]
        }

        let restoredWebPageItem = try #require(adapter.webPages.first {
            $0.url.absoluteString == "https://openai.com"
        })

        #expect(context.undoDeleteWebPageUseCaseSpy.calledIDs == ["web-page-id"])
        #expect(!restoredWebPageItem.isHidden)
    }

    @Test("HomeFeature startObserving은 네트워크 연결 상태를 반영한다")
    func HomeFeature_startObserving은_네트워크_연결_상태를_반영한다() async {
        let networkUseCaseSpy = ObserveNetworkConnectivityUseCaseSpy()
        let adapter = HomeStoreTestAdapter(networkConnectivityUseCase: networkUseCaseSpy)

        await adapter.startObserving()

        #expect(adapter.isNetworkConnected)

        networkUseCaseSpy.currentValueSubject.send(false)
        await adapter.settle()

        #expect(!adapter.isNetworkConnected)
    }
}

private enum HomeTestError: Error {
    case failure
}
