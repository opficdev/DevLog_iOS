//
//  FetchTodosByKindUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 2/1/26.
//

protocol FetchTodosByKindUseCase {
    var repository: TodoRepository { get }
    func execute(_ kind: TodoKind) async throws -> [Todo]
}
