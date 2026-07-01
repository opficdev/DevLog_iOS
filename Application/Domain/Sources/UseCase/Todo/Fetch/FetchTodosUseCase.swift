//
//  FetchTodosUseCase.swift
//  Domain
//
//  Created by opfic on 3/3/26.
//

import Core

public protocol FetchTodosUseCase {
    func execute(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage
}
