//
//  GoalTodoLinkFeatureTests.swift
//  DevelopmentTests
//
//  Created by opfic on 9/15/26.
//

import Testing
import Core
import Domain
import PresentationShared
@testable import Development

@MainActor
struct GoalTodoLinkFeatureTests {
    @Test("검색 결과를 카테고리별 섹션으로 구성한다")
    func 검색_결과를_카테고리별_섹션으로_구성한다() {
        let feature = makeTodo(
            id: "feature",
            number: 1,
            title: "기능 구현",
            category: .system(.feature)
        )
        let document = makeTodo(
            id: "document",
            number: 2,
            title: "기능 문서화",
            category: .system(.doc)
        )
        let improvement = makeTodo(
            id: "improvement",
            number: 3,
            title: "성능 개선",
            category: .system(.improvement)
        )
        var state = GoalTodoLinkFeature.State(
            goalId: "goal",
            todos: [feature, document, improvement]
        )

        state.searchText = "기능"

        #expect(state.filteredTodos == [feature, document])
        #expect(state.sections.map(\.todos) == [[feature], [document]])
    }

    @Test("선택을 완료하면 기존 연결을 해제하고 새 Todo를 연결한다")
    func 선택을_완료하면_기존_연결을_해제하고_새_Todo를_연결한다() async {
        let linked = makeTodo(id: "linked", number: 1, title: "기존", goalId: "goal")
        let unlinked = makeTodo(id: "unlinked", number: 2, title: "신규")
        let spy = UpdateTodoGoalUseCaseSpy(results: [.success(()), .success(())])
        let store = TestStore(
            initialState: GoalTodoLinkFeature.State(
                goalId: "goal",
                todos: [linked, unlinked]
            )
        ) {
            GoalTodoLinkFeature()
        } withDependencies: {
            $0.developmentUpdateTodoGoalUseCase = spy
        }

        await store.send(.view(.toggleTodo(linked.id))) {
            $0.selectedTodoIDs = []
        }
        await store.send(.view(.toggleTodo(unlinked.id))) {
            $0.selectedTodoIDs = [unlinked.id]
        }
        await store.send(.view(.save)) {
            $0.isUpdating = true
        }

        var newlyUnlinked = linked
        newlyUnlinked.goalId = nil
        var newlyLinked = unlinked
        newlyLinked.goalId = "goal"
        await store.receive(.store(.linksUpdated([unlinked.id]))) {
            $0.todos = [newlyUnlinked, newlyLinked]
            $0.isUpdating = false
        }
        await store.receive(.delegate(.saved([newlyUnlinked, newlyLinked])))

        #expect(await spy.requests() == [
            .init(todoId: linked.id, goalId: nil),
            .init(todoId: unlinked.id, goalId: "goal")
        ])
    }

    @Test("Todo 연결 변경이 실패하면 실제 연결 상태를 다시 불러온다")
    func Todo_연결_변경이_실패하면_실제_연결_상태를_다시_불러온다() async {
        let todo = makeTodo(id: "todo", number: 1, title: "연결 대상")
        let updateSpy = UpdateTodoGoalUseCaseSpy(results: [.failure(RecordTestError.failed)])
        var state = GoalTodoLinkFeature.State(goalId: "goal", todos: [todo])
        state.selectedTodoIDs = [todo.id]
        let store = TestStore(initialState: state) {
            GoalTodoLinkFeature()
        } withDependencies: {
            $0.developmentUpdateTodoGoalUseCase = updateSpy
            $0.developmentFetchTodosUseCase = FetchTodosUseCaseStub(
                result: .success(TodoPage(items: [todo], nextCursor: nil))
            )
        }

        await store.send(.view(.save)) {
            $0.isUpdating = true
        }
        await store.receive(.store(.linkUpdateFailed)) {
            $0.isUpdating = false
            $0.isLoading = true
            $0.alert = makeRecordErrorAlert("development_goal_todo_update_error_message")
        }
        await store.receive(.store(.loadedTodos([todo]))) {
            $0.selectedTodoIDs = []
            $0.isLoading = false
        }

        #expect(await updateSpy.requests() == [
            .init(todoId: todo.id, goalId: "goal")
        ])
    }
}
