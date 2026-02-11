//
//  UpsertTodoUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 12/8/25.
//

protocol UpsertTodoUseCase {
    func execute(_ todo: Todo) async throws
}
