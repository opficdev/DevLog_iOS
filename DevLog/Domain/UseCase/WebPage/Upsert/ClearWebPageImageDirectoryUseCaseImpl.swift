//
//  ClearWebPageImageDirectoryUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 4/14/26.
//

final class ClearWebPageImageDirectoryUseCaseImpl: ClearWebPageImageDirectoryUseCase {
    private let repository: WebPageImageRepository

    init(_ repository: WebPageImageRepository) {
        self.repository = repository
    }

    func execute() throws {
        try repository.clearDirectory()
    }
}
