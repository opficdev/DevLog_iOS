//
//  WidgetTodoSnapshotRepositoryGraph.swift
//  Data
//
//  Created by opfic on 9/7/26.
//

import Cradle
import Domain

public struct WidgetTodoSnapshotRepositoryGraphInput {
    public let queryService: TodoQueryService
    public let todoCategoryService: TodoCategoryService
    public let store: MemoryCacheStore

    public init(
        queryService: TodoQueryService,
        todoCategoryService: TodoCategoryService,
        store: MemoryCacheStore
    ) {
        self.queryService = queryService
        self.todoCategoryService = todoCategoryService
        self.store = store
    }
}

@DependencyGraph(input: WidgetTodoSnapshotRepositoryGraphInput.self)
public final class WidgetTodoSnapshotRepositoryGraph {
    @Provide
    private func makeWidgetTodoSnapshotRepository() -> WidgetTodoSnapshotRepository {
        WidgetTodoSnapshotRepositoryImpl(
            queryService: input.queryService,
            todoCategoryService: input.todoCategoryService,
            store: input.store
        )
    }
}
