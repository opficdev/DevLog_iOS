//
//  UndoDeleteWebPageUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 3/16/26.
//

public final class UndoDeleteWebPageUseCaseImpl: UndoDeleteWebPageUseCase {
    private let repository: WebPageRepository

    init(_ repository: WebPageRepository) {
        self.repository = repository
    }

    public func execute(_ id: String) async throws {
        try await repository.undoDelete(id)
    }
}
