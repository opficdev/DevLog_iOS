//
//  FetchTodosByKeywordUseCase.swift
//  DevLog
//
//  Created by opfic on 2/21/26.
//

protocol FetchTodosByKeywordUseCase {
    func execute(_ keyword: String) async throws -> [Todo]
}
