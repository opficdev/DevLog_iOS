//
//  TodoListFeatureTests.swift
//  DevLogPresentationTests
//
//  Created by opfic on 6/12/26.
//

import Testing
import Foundation
import ComposableArchitecture
import DevLogCore
import DevLogDomain
@testable import DevLogPresentation

@MainActor
struct TodoListFeatureTests {
    @Test("onAppear는 첫 페이지를 조회하고 목록과 hasMore 상태를 갱신한다")
    func onAppear는_첫_페이지를_조회하고_목록과_hasMore_상태를_갱신한다() async {
        let todos = (0..<20).map { makeTodoListTodo(id: "todo-\($0)", number: $0) }
        let cursor = makeTodoListCursor(documentID: "cursor-1")
        let fetchSpy = TodoListFetchTodosUseCaseSpy(pages: [
            TodoPage(items: todos, nextCursor: cursor)
        ])
        let adapter = TodoListStoreTestAdapter(fetchUseCase: fetchSpy)

        await adapter.onAppear()

        await waitUntil {
            adapter.todos.count == 20
        }

        #expect(fetchSpy.queries.map(\.categoryId) == ["feature"])
        #expect(fetchSpy.cursors.map { $0?.documentID } == [nil])
        #expect(adapter.todos == todos.compactMap(TodoListItem.init(from:)))
        #expect(adapter.hasMore)
    }

    @Test("loadNextPage는 다음 커서로 조회한 Todo를 기존 목록 뒤에 추가한다")
    func loadNextPage는_다음_커서로_조회한_Todo를_기존_목록_뒤에_추가한다() async {
        let firstTodos = (0..<20).map { makeTodoListTodo(id: "todo-\($0)", number: $0) }
        let nextTodo = makeTodoListTodo(id: "todo-next", number: 20)
        let cursor = makeTodoListCursor(documentID: "cursor-1")
        let fetchSpy = TodoListFetchTodosUseCaseSpy(pages: [
            TodoPage(items: firstTodos, nextCursor: cursor),
            TodoPage(items: [nextTodo], nextCursor: nil)
        ])
        let adapter = TodoListStoreTestAdapter(fetchUseCase: fetchSpy)

        await adapter.onAppear()

        await waitUntil {
            adapter.todos.count == 20
        }

        await adapter.loadNextPage()

        await waitUntil {
            adapter.todos.count == 21
        }

        #expect(fetchSpy.cursors.map { $0?.documentID } == [nil, "cursor-1"])
        #expect(adapter.todos.last == TodoListItem(from: nextTodo))
        #expect(!adapter.hasMore)
    }

    @Test("새 목록 조회는 이전 요청을 취소하고 마지막 응답만 반영한다")
    func 새_목록_조회는_이전_요청을_취소하고_마지막_응답만_반영한다() async {
        let firstTodo = makeTodoListTodo(id: "todo-first", number: 1)
        let secondTodo = makeTodoListTodo(id: "todo-second", number: 2)
        let fetchSpy = TodoListDelayedFirstFetchTodosUseCaseSpy(pages: [
            TodoPage(items: [firstTodo], nextCursor: nil),
            TodoPage(items: [secondTodo], nextCursor: nil)
        ])
        let adapter = TodoListStoreTestAdapter(fetchUseCase: fetchSpy)

        await adapter.onAppear()
        await adapter.setSortTarget(.updatedAt)

        await waitUntil(timeout: .seconds(2)) {
            adapter.todos == [TodoListItem(from: secondTodo)!]
        }

        let queries = await fetchSpy.calledQueries()
        let cancelledCalls = await fetchSpy.cancelledCalls()

        #expect(adapter.todos == [TodoListItem(from: secondTodo)!])
        #expect(queries.map(\.sortTarget) == [.createdAt, .updatedAt])
        #expect(cancelledCalls == [0])
        #expect(!adapter.showAlert)
    }

    @Test("필터와 정렬 액션은 query와 적용 필터 수를 갱신한다")
    func 필터와_정렬_액션은_query와_적용_필터_수를_갱신한다() async {
        let adapter = TodoListStoreTestAdapter()

        await adapter.setSortTarget(.updatedAt)
        await adapter.setSortOrder(.oldest)
        await adapter.togglePinnedOnly()
        await adapter.setCompletionFilter(.completed)

        #expect(adapter.query.sortTarget == .updatedAt)
        #expect(adapter.query.sortOrder == .oldest)
        #expect(adapter.query.isPinned == true)
        #expect(adapter.query.completionFilter == .completed)
        #expect(adapter.appliedFilterCount == 4)

        await adapter.resetFilters()

        #expect(adapter.query == TodoQuery(categoryId: "feature"))
        #expect(adapter.appliedFilterCount == 0)
    }

    @Test("setSearchText는 표시 범위를 초기화하고 디바운스 후 검색 결과를 반영한다")
    func setSearchText는_표시_범위를_초기화하고_디바운스_후_검색_결과를_반영한다() async {
        let todo = makeTodoListTodo(id: "todo-search", title: "Swift")
        let fetchSpy = TodoListFetchTodosUseCaseSpy(pages: [
            TodoPage(items: [todo], nextCursor: nil)
        ])
        let adapter = TodoListStoreTestAdapter(fetchUseCase: fetchSpy)

        await adapter.setShowAllSearchResults(true)
        await adapter.setSearchText(" swift ")

        #expect(adapter.searchText == " swift ")
        #expect(!adapter.showAllSearchResults)

        await waitUntil(timeout: .seconds(2)) {
            adapter.searchResults == [TodoListItem(from: todo)]
        }

        #expect(fetchSpy.queries.map(\.keyword) == ["swift"])
        #expect(fetchSpy.cursors.map { $0?.documentID } == [nil])
        #expect(!adapter.isLoading)
    }

    @Test("setIsSearching false는 검색 상태와 검색 결과 표시 상태를 초기화한다")
    func setIsSearching_false는_검색_상태와_검색_결과_표시_상태를_초기화한다() async {
        let todo = TodoListItem(from: makeTodoListTodo(id: "todo-search"))!
        let adapter = TodoListStoreTestAdapter()

        await adapter.setSearchResults([todo])
        await adapter.setShowAllSearchResults(true)
        await adapter.setSearchText("swift")
        await adapter.setIsSearching(true)
        await adapter.setIsSearching(false)

        #expect(!adapter.isSearching)
        #expect(adapter.searchText.isEmpty)
        #expect(adapter.searchResults.isEmpty)
        #expect(!adapter.showAllSearchResults)
        #expect(!adapter.isLoading)
    }

    @Test("fullScreenCover 상태를 설정하고 dismiss 할 수 있다")
    func fullScreenCover_상태를_설정하고_dismiss_할_수_있다() async {
        let adapter = TodoListStoreTestAdapter()

        await adapter.setFullScreenCover(.editor)
        #expect(adapter.fullScreenCover == .editor)

        await adapter.dismissFullScreenCover()
        #expect(adapter.fullScreenCover == nil)
    }

    @Test("swipeTodo는 Todo를 숨기고 undoDelete와 finishDeleteToast는 숨김 상태를 되돌리거나 제거한다")
    func swipeTodo는_Todo를_숨기고_undoDelete와_finishDeleteToast는_숨김_상태를_되돌리거나_제거한다() async {
        let todo = makeTodoListTodo(id: "todo-delete")
        let item = TodoListItem(from: todo)!
        let deleteSpy = TodoListDeleteTodoUseCaseSpy()
        let undoSpy = TodoListUndoDeleteTodoUseCaseSpy()
        let adapter = TodoListStoreTestAdapter(
            deleteUseCase: deleteSpy,
            undoDeleteUseCase: undoSpy
        )

        await adapter.appendTodos([item])
        await adapter.setSearchResults([item])
        await adapter.swipeTodo(item)

        #expect(adapter.todos.first?.isHidden == true)
        #expect(adapter.searchResults.first?.isHidden == true)

        await waitUntil {
            deleteSpy.todoIds == ["todo-delete"]
        }

        await adapter.undoDelete()

        #expect(adapter.todos.first?.isHidden == false)
        #expect(adapter.searchResults.first?.isHidden == false)

        await waitUntil {
            undoSpy.todoIds == ["todo-delete"]
        }

        await adapter.swipeTodo(item)
        await adapter.finishDeleteToast("todo-delete")

        #expect(adapter.todos.isEmpty)
        #expect(adapter.searchResults.isEmpty)
    }

    @Test("tapToggleCompleted와 tapTogglePinned는 조회한 Todo를 갱신해 목록에 반영한다")
    func tapToggleCompleted와_tapTogglePinned는_조회한_Todo를_갱신해_목록에_반영한다() async {
        let todo = makeTodoListTodo(id: "todo-toggle", isPinned: false, isCompleted: false)
        let item = TodoListItem(from: todo)!
        let fetchByIdSpy = TodoListFetchTodoByIdUseCaseSpy(todos: [todo])
        let upsertSpy = TodoListUpsertTodoUseCaseSpy()
        let trackSpy = TodoListTrackAnalyticsEventUseCaseSpy()
        let adapter = TodoListStoreTestAdapter(
            fetchTodoByIdUseCase: fetchByIdSpy,
            upsertUseCase: upsertSpy,
            trackAnalyticsEventUseCase: trackSpy
        )

        await adapter.appendTodos([item])
        await adapter.tapToggleCompleted(item)

        await waitUntil {
            adapter.todos.first?.isCompleted == true
        }

        #expect(upsertSpy.todos.first?.isCompleted == true)
        #expect(trackSpy.hasTrackedTodoComplete)

        fetchByIdSpy.todos = [upsertSpy.todos[0]]
        await adapter.tapTogglePinned(adapter.todos[0])

        await waitUntil {
            adapter.todos.first?.isPinned == true
        }

        #expect(upsertSpy.todos.last?.isPinned == true)
    }

    @Test("Todo 조회 실패 시 공통 에러 알림 상태를 표시한다")
    func Todo_조회_실패_시_공통_에러_알림_상태를_표시한다() async {
        let fetchSpy = TodoListFetchTodosUseCaseSpy()
        fetchSpy.error = TodoListTestError.failure
        let adapter = TodoListStoreTestAdapter(fetchUseCase: fetchSpy)

        await adapter.onAppear()

        await waitUntil {
            adapter.showAlert
        }

        #expect(adapter.showAlert)
        #expect(adapter.alert == expectedTodoListErrorAlert())
    }
}
