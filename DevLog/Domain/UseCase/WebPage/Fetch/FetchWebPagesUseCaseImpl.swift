//
//  FetchWebUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/9/26.
//

final class FetchWebPagesUseCaseImpl: FetchWebPagesUseCase {
    let repository: WebPageRepository

    init(_ repository: WebPageRepository) {
        self.repository = repository
    }

    func execute() async throws -> [WebPage] {
        return try await repository.fetch().map { $0.toDomain() }
    }
}
