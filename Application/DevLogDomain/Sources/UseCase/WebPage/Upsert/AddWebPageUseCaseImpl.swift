//
//  AddWebPageUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/9/26.
//

public final class AddWebPageUseCaseImpl: AddWebPageUseCase {
    private let repository: WebPageRepository

    init(_ repository: WebPageRepository) {
        self.repository = repository
    }

    public func execute(_ urlString: String) async throws {
        try await repository.upsert(urlString)
    }
}
