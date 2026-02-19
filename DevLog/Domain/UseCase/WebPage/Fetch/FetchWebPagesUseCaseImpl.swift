//
//  FetchWebUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/9/26.
//

final class FetchWebPagesUseCaseImpl: FetchWebPagesUseCase {
    private let repository: WebPageRepository

    init(_ repository: WebPageRepository) {
        self.repository = repository
    }

    func execute() async throws -> [WebPage] {
        try await repository.fetch()
    }
}
