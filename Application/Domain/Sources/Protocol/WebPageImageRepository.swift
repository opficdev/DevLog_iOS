//
//  WebPageImageRepository.swift
//  Domain
//
//  Created by opfic on 4/14/26.
//

public protocol WebPageImageRepository {
    func fetchDirSizeInBytes() async -> Int64
    func clearDirectory() async throws
}
