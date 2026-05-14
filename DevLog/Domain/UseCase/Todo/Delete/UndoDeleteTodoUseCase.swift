//
//  UndoDeleteTodoUseCase.swift
//  DevLog
//
//  Created by opfic on 3/15/26.
//

public protocol UndoDeleteTodoUseCase {
    func execute(_ todoId: String) async throws
}
