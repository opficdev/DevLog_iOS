//
//  DeleteWebPageTests.swift
//  DevLogPresentationTests
//
//  Created by opfic on 4/6/26.
//

import Testing
import Foundation
import DevLogDomain
@testable import DevLogPresentation

@MainActor
struct DeleteWebPageTests {
    @Test("웹페이지를 삭제하면 항목이 즉시 숨겨지고 되돌리기 토스트가 표시되며 삭제 유스케이스가 호출된다")
    func 웹페이지를_삭제하면_항목이_즉시_숨겨지고_되돌리기_토스트가_표시되며_삭제_유스케이스가_호출된다() async throws {
        let fetchTodoCategoryPreferencesUseCaseSpy = FetchTodoCategoryPreferencesUseCaseSpy()
        let updateTodoCategoryPreferencesUseCaseSpy = UpdateTodoCategoryPreferencesUseCaseSpy()
        let addWebPageUseCaseSpy = AddWebPageUseCaseSpy()
        let deleteWebPageUseCaseSpy = DeleteWebPageUseCaseSpy()
        let undoDeleteWebPageUseCaseSpy = UndoDeleteWebPageUseCaseSpy()
        let upsertTodoUseCaseSpy = UpsertTodoUseCaseSpy()
        let fetchTodosUseCaseSpy = FetchTodosUseCaseSpy()
        let fetchWebPagesUseCaseSpy = FetchWebPagesUseCaseSpy(
            webPages: [
                WebPage(
                    title: "OpenAI",
                    url: URL(string: "https://openai.com")!,
                    displayURL: URL(string: "https://openai.com")!,
                    imageURL: nil
                )
            ]
        )
        let observeNetworkConnectivityUseCaseSpy = ObserveNetworkConnectivityUseCaseSpy()

        let homeViewModel = HomeViewModel(
            fetchPreferencesUseCase: fetchTodoCategoryPreferencesUseCaseSpy,
            updatePreferencesUseCase: updateTodoCategoryPreferencesUseCaseSpy,
            addWebPageUseCase: addWebPageUseCaseSpy,
            deleteWebPageUseCase: deleteWebPageUseCaseSpy,
            undoDeleteWebPageUseCase: undoDeleteWebPageUseCaseSpy,
            upsertTodoUseCase: upsertTodoUseCaseSpy,
            fetchTodosUseCase: fetchTodosUseCaseSpy,
            fetchWebPagesUseCase: fetchWebPagesUseCaseSpy,
            networkConnectivityUseCase: observeNetworkConnectivityUseCaseSpy
        )

        homeViewModel.send(.loadInitialData)
        await waitUntil {
            !homeViewModel.state.webPages.isEmpty
        }

        let webPageItem = try #require(homeViewModel.state.webPages.first)

        homeViewModel.send(.deleteWebPage(webPageItem))

        #expect(homeViewModel.state.webPages.filter { !$0.isHidden }.isEmpty)
        #expect(homeViewModel.state.showToast)

        await waitUntil {
            deleteWebPageUseCaseSpy.calledUrlStrings == ["https://openai.com"]
        }

        #expect(deleteWebPageUseCaseSpy.calledUrlStrings == ["https://openai.com"])
    }

    @Test("웹페이지 삭제를 되돌리면 되돌리기 유스케이스가 호출되고 숨김 상태가 해제된다")
    func 웹페이지_삭제를_되돌리면_되돌리기_유스케이스가_호출되고_숨김_상태가_해제된다() async throws {
        let fetchTodoCategoryPreferencesUseCaseSpy = FetchTodoCategoryPreferencesUseCaseSpy()
        let updateTodoCategoryPreferencesUseCaseSpy = UpdateTodoCategoryPreferencesUseCaseSpy()
        let addWebPageUseCaseSpy = AddWebPageUseCaseSpy()
        let deleteWebPageUseCaseSpy = DeleteWebPageUseCaseSpy()
        let undoDeleteWebPageUseCaseSpy = UndoDeleteWebPageUseCaseSpy()
        let upsertTodoUseCaseSpy = UpsertTodoUseCaseSpy()
        let fetchTodosUseCaseSpy = FetchTodosUseCaseSpy()
        let fetchWebPagesUseCaseSpy = FetchWebPagesUseCaseSpy(
            webPages: [
                WebPage(
                    title: "OpenAI",
                    url: URL(string: "https://openai.com")!,
                    displayURL: URL(string: "https://openai.com")!,
                    imageURL: nil
                )
            ]
        )
        let observeNetworkConnectivityUseCaseSpy = ObserveNetworkConnectivityUseCaseSpy()

        let homeViewModel = HomeViewModel(
            fetchPreferencesUseCase: fetchTodoCategoryPreferencesUseCaseSpy,
            updatePreferencesUseCase: updateTodoCategoryPreferencesUseCaseSpy,
            addWebPageUseCase: addWebPageUseCaseSpy,
            deleteWebPageUseCase: deleteWebPageUseCaseSpy,
            undoDeleteWebPageUseCase: undoDeleteWebPageUseCaseSpy,
            upsertTodoUseCase: upsertTodoUseCaseSpy,
            fetchTodosUseCase: fetchTodosUseCaseSpy,
            fetchWebPagesUseCase: fetchWebPagesUseCaseSpy,
            networkConnectivityUseCase: observeNetworkConnectivityUseCaseSpy
        )

        homeViewModel.send(.loadInitialData)
        await waitUntil {
            !homeViewModel.state.webPages.isEmpty
        }

        let webPageItem = try #require(homeViewModel.state.webPages.first)

        homeViewModel.send(.deleteWebPage(webPageItem))
        homeViewModel.send(.undoDeleteWebPage)

        await waitUntil {
            undoDeleteWebPageUseCaseSpy.calledUrlStrings == ["https://openai.com"]
        }

        let restoredWebPageItem = try #require(homeViewModel.state.webPages.first {
            $0.url.absoluteString == "https://openai.com"
        })

        #expect(undoDeleteWebPageUseCaseSpy.calledUrlStrings == ["https://openai.com"])
        #expect(!restoredWebPageItem.isHidden)
    }
}
