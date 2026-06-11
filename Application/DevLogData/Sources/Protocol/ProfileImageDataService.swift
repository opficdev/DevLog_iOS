//
//  ProfileImageDataService.swift
//  DevLogData
//
//  Created by opfic on 6/11/26.
//

import Foundation

public protocol ProfileImageDataService {
    func fetchImageData(from url: URL) async throws -> Data
}
