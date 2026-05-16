//
//  FetchReferenceItemsUseCaseImpl.swift
//  DevLogDomain
//
//  Created by opfic on 3/25/26.
//

public final class FetchReferenceItemsUseCaseImpl: FetchReferenceItemsUseCase {
    private let repository: TodoRepository

    init(_ repository: TodoRepository) {
        self.repository = repository
    }

    public func execute(_ numbers: [Int]) async throws -> [Int: TodoReference] {
        try await repository.fetchReferences(numbers)
    }
}
