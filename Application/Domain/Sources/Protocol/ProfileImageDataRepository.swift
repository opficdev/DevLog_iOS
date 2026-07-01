//
//  ProfileImageDataRepository.swift
//  Domain
//
//  Created by opfic on 6/11/26.
//

import Foundation

public protocol ProfileImageDataRepository {
    func fetchImageData(from url: URL) async throws -> Data
}
