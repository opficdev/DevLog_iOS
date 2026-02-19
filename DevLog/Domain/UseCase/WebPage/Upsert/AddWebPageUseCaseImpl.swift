//
//  AddWebPageUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/9/26.
//

final class AddWebPageUseCaseImpl: AddWebPageUseCase {
    private let repository: WebPageRepository

    init(_ repository: WebPageRepository) {
        self.repository = repository
    }

    func execute(_ urlString: String) async throws -> WebPage {
        try await repository.upsert(urlString)
    }
}
