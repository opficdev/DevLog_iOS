//
//  FetchTodoIDsByNumbersUseCase.swift
//  DevLog
//
//  Created by opfic on 3/25/26.
//

protocol FetchTodoIDsByNumbersUseCase {
    func execute(_ numbers: [Int]) async throws -> [Int: String]
}
