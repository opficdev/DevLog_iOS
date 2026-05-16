//
//  FetchTodosUseCase.swift
//  DevLogDomain
//
//  Created by opfic on 3/3/26.
//

public protocol FetchTodosUseCase {
    func execute(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage
}
