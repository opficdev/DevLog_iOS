//
//  TodoRepositoryImplTests.swift
//  DataTests
//
//  Created by opfic on 8/28/26.
//

import Foundation
import Testing
import Core
import Domain
@testable import Data

struct TodoRepositoryImplTests {
    @Test("Todo 조회는 Query service에만 전달한다")
    func Todo_조회는_Query_service에만_전달한다() async throws {
        let queryService = TodoRepositoryQueryServiceSpy()
        let commandService = TodoRepositoryCommandServiceSpy()
        let repository = makeTodoRepository(
            queryService: queryService,
            commandService: commandService
        )

        let page = try await repository.fetchTodos(.init(), cursor: nil)

        #expect(page.items.map(\.id) == ["todo-1"])
        #expect(await queryService.fetchTodoQueries() == [.init()])
        #expect(await commandService.upsertRequests().isEmpty)
    }

    @Test("Todo 저장은 Command service에만 전달한다")
    func Todo_저장은_Command_service에만_전달한다() async throws {
        let queryService = TodoRepositoryQueryServiceSpy()
        let commandService = TodoRepositoryCommandServiceSpy()
        let repository = makeTodoRepository(
            queryService: queryService,
            commandService: commandService
        )

        try await repository.upsertTodo(makeTodoRepositoryTodo())

        let request = try #require(await commandService.upsertRequests().first)
        #expect(request.id == "todo-1")
        #expect(await queryService.fetchTodoQueries().isEmpty)
    }
}
