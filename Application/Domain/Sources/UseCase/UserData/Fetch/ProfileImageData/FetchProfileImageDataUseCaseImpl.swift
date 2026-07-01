//
//  FetchProfileImageDataUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 6/11/26.
//

import Foundation

public final class FetchProfileImageDataUseCaseImpl: FetchProfileImageDataUseCase {
    private let repository: ProfileImageDataRepository

    public init(_ repository: ProfileImageDataRepository) {
        self.repository = repository
    }

    public func execute(from url: URL) async throws -> Data {
        try await repository.fetchImageData(from: url)
    }
}
