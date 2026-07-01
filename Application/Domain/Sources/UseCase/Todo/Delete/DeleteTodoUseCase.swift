//
//  DeleteTodoUseCase.swift
//  Domain
//
//  Created by 최윤진 on 2/12/26.
//

public protocol DeleteTodoUseCase {
    func execute(_ todoId: String) async throws
}
