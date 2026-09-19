//
//  GoalDetailTodoTestSupport.swift
//  DevelopmentTests
//
//  Created by opfic on 9/15/26.
//

import Core
import Domain
import Foundation

struct FetchTodosUseCaseStub: FetchTodosUseCase {
    let result: Result<TodoPage, Error>

    init(result: Result<TodoPage, Error> = .success(TodoPage(items: [], nextCursor: nil))) {
        self.result = result
    }

    func execute(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        try result.get()
    }
}

final class FetchTodosUseCaseSpy: FetchTodosUseCase {
    private let page: TodoPage
    private let recorder = FetchTodosUseCaseCallRecorder()

    init(page: TodoPage) {
        self.page = page
    }

    func execute(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage {
        await recorder.append(query)
        return page
    }

    func queries() async -> [TodoQuery] {
        await recorder.queries()
    }
}

private actor FetchTodosUseCaseCallRecorder {
    private var recordedQueries = [TodoQuery]()

    func append(_ query: TodoQuery) {
        recordedQueries.append(query)
    }

    func queries() -> [TodoQuery] {
        recordedQueries
    }
}

actor UpdateTodoGoalUseCaseSpy: UpdateTodoGoalUseCase {
    struct Request: Equatable {
        let todoId: String
        let goalId: String?
    }

    private var results: [Result<Void, Error>]
    private var recordedRequests = [Request]()

    init(results: [Result<Void, Error>] = [.success(())]) {
        self.results = results
    }

    func execute(todoId: String, goalId: String?) async throws {
        recordedRequests.append(.init(todoId: todoId, goalId: goalId))
        guard !results.isEmpty else { return }
        try results.removeFirst().get()
    }

    func requests() -> [Request] {
        recordedRequests
    }
}

func makeTodo(
    id: String,
    number: Int,
    title: String,
    goalId: String? = nil,
    category: TodoCategory = .system(.feature)
) -> Todo {
    let date = Date(timeIntervalSince1970: 1_700_000_000 + Double(number))
    return Todo(
        id: id,
        isPinned: false,
        isCompleted: false,
        isChecked: false,
        number: number,
        title: title,
        content: "",
        createdAt: date,
        updatedAt: date,
        completedAt: nil,
        deletedAt: nil,
        dueDate: nil,
        tags: [],
        category: category,
        goalId: goalId
    )
}
