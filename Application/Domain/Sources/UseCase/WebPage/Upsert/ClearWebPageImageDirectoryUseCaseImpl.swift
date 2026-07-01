//
//  ClearWebPageImageDirectoryUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 4/14/26.
//

public final class ClearWebPageImageDirectoryUseCaseImpl: ClearWebPageImageDirectoryUseCase {
    private let repository: WebPageImageRepository

    init(_ repository: WebPageImageRepository) {
        self.repository = repository
    }

    public func execute() async throws {
        try await repository.clearDirectory()
    }
}
