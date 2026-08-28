//
//  WidgetTodoSnapshotRepositoryImplTests.swift
//  DataTests
//
//  Created by opfic on 8/28/26.
//

import Testing
import Core
@testable import Data

struct WidgetTodoSnapshotRepositoryImplTests {
    @Test("Widget 오늘 Todo 조회는 Query service에만 전달한다")
    func Widget_오늘_Todo_조회는_Query_service에만_전달한다() async throws {
        let queryService = TodoRepositoryQueryServiceSpy()
        let repository = WidgetTodoSnapshotRepositoryImpl(queryService: queryService)

        let snapshots = try await repository.fetchTodayTodos(
            dueDateFilter: .withDueDate,
            sortTarget: .dueDate,
            sortOrder: .latest,
            pageSize: 10
        )

        let query = try #require(await queryService.fetchTodoQueries().first)
        #expect(snapshots.map(\.id) == ["todo-1"])
        #expect(query.completionFilter == .incomplete)
        #expect(query.dueDateFilter == .withDueDate)
        #expect(query.fetchAllPages)
    }
}
