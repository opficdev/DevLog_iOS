//
//  FetchReferenceItemsUseCase.swift
//  DevLogDomain
//
//  Created by opfic on 3/25/26.
//

public protocol FetchReferenceItemsUseCase {
    func execute(_ numbers: [Int]) async throws -> [Int: TodoReference]
}
