//
//  FetchPinnedTodosUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 11/29/25.
//

protocol FetchPinnedTodosUseCase {
    func execute() async throws -> [Todo]
}
