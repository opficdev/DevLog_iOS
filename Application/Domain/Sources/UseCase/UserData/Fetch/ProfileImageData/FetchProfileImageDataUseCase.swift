//
//  FetchProfileImageDataUseCase.swift
//  Domain
//
//  Created by opfic on 6/11/26.
//

import Foundation

public protocol FetchProfileImageDataUseCase {
    func execute(from url: URL) async throws -> Data
}
