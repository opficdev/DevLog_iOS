//
//  FetchTodoUseCase.swift
//  DevLogDomain
//
//  Created by opfic on 2/15/26.
//

public protocol FetchTodoByIdUseCase {
    func execute(_ todoId: String) async throws -> Todo
}
