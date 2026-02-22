//
//  FetchTodosByKindUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 2/1/26.
//

protocol FetchTodosByKindUseCase {
    func execute(_ kind: TodoKind, cursor: TodoCursor?) async throws -> TodoPage
}
