//
//  FetchReferenceItemsUseCase.swift
//  DevLog
//
//  Created by opfic on 3/25/26.
//

protocol FetchReferenceItemsUseCase {
    func execute(_ numbers: [Int]) async throws -> [Int: TodoReferenceItem]
}
