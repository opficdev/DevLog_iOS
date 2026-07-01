//
//  UpsertTodoUseCase.swift
//  Domain
//
//  Created by 최윤진 on 12/8/25.
//

public protocol UpsertTodoUseCase {
    func execute(_ todo: Todo) async throws
    func execute(_ todoDraft: TodoDraft) async throws
}
