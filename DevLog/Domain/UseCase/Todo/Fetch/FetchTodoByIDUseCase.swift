//
//  FetchTodoUseCase.swift
//  DevLog
//
//  Created by opfic on 2/15/26.
//

protocol FetchTodoByIdUseCase {
    func execute(_ todoId: String) async throws -> Todo
}
