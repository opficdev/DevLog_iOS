//
//  FetchTodosUseCase.swift
//  DevLog
//
//  Created by opfic on 3/3/26.
//

protocol FetchTodosUseCase {
    func execute(_ query: TodoQuery, cursor: TodoCursor?) async throws -> TodoPage
}
