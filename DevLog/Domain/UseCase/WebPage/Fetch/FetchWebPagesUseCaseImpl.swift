//
//  FetchWebUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/9/26.
//

public final class FetchWebPagesUseCaseImpl: FetchWebPagesUseCase {
    private let repository: WebPageRepository

    init(_ repository: WebPageRepository) {
        self.repository = repository
    }

    public func execute(_ query: String) async throws -> [WebPage] {
        try await repository.fetch(query)
    }
}
