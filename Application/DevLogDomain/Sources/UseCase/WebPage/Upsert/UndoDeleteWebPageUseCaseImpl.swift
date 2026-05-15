//
//  UndoDeleteWebPageUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 3/16/26.
//

public final class UndoDeleteWebPageUseCaseImpl: UndoDeleteWebPageUseCase {
    private let repository: WebPageRepository

    init(_ repository: WebPageRepository) {
        self.repository = repository
    }

    public func execute(_ urlString: String) async throws {
        try await repository.undoDelete(urlString)
    }
}
