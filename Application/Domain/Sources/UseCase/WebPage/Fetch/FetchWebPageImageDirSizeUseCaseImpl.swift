//
//  FetchWebPageImageDirSizeUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 4/14/26.
//

public final class FetchWebPageImageDirSizeUseCaseImpl: FetchWebPageImageDirSizeUseCase {
    private let repository: WebPageImageRepository

    init(_ repository: WebPageImageRepository) {
        self.repository = repository
    }

    public func execute() async -> Int64 {
        await repository.fetchDirSizeInBytes()
    }
}
