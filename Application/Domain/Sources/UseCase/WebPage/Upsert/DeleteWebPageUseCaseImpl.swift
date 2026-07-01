//
//  DeleteWebPageUseCaseImpl.swift
//  Domain
//
//  Created by 최윤진 on 2/9/26.
//

public final class DeleteWebPageUseCaseImpl: DeleteWebPageUseCase {
    private let repository: WebPageRepository

    init(_ repository: WebPageRepository) {
        self.repository = repository
    }

    public func execute(id: String, urlString: String) async throws {
        try await repository.delete(id: id, urlString: urlString)
    }
}
