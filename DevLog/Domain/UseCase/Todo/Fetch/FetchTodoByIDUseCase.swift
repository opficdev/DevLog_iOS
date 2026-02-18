//
//  FetchTodoUseCase.swift
//  DevLog
//
//  Created by opfic on 2/15/26.
//

protocol FetchTodoByIDUseCase {
    func execute(_ todoID: String) async throws -> Todo
}
