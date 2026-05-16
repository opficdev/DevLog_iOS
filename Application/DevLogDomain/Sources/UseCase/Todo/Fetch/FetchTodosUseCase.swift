//
//  FetchTodosUseCase.swift
//  DevLogDomain
//
//  Created by opfic on 3/3/26.
//

import DevLogCore

public protocol FetchTodosUseCase {
    func execute(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage
}
