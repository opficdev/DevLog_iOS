//
//  UpsertTodoUseCasing.swift
//  DevLog
//
//  Created by 최윤진 on 12/8/25.
//

protocol UpsertTodoUseCasing {
    var repository: TodoRepository { get }
    func execute(_ todo: Todo) async throws
}
