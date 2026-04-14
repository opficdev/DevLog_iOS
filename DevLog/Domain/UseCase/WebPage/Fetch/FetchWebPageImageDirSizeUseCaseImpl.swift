//
//  FetchWebPageImageDirSizeUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 4/14/26.
//

final class FetchWebPageImageDirSizeUseCaseImpl: FetchWebPageImageDirSizeUseCase {
    private let repository: WebPageImageRepository

    init(_ repository: WebPageImageRepository) {
        self.repository = repository
    }

    func execute() async -> Int64 {
        await repository.fetchDirSizeInBytes()
    }
}
