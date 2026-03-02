//
//  FetchTodosByDateRangeUseCase.swift
//  DevLog
//
//  Created by opfic on 3/1/26.
//

import Foundation

protocol FetchTodosByDateRangeUseCase {
    func execute(from startDate: Date, to endDate: Date) async throws -> [Todo]
}
