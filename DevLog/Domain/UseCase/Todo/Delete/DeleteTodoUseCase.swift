//
//  DeleteTodoUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 2/12/26.
//

protocol DeleteTodoUseCase {
    func execute(_ todoID: String) async throws
}
