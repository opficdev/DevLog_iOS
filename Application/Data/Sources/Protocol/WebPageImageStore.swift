//
//  WebPageImageStore.swift
//  Data
//
//  Created by opfic on 5/14/26.
//

import Foundation

public protocol WebPageImageStore {
    func cachedImageURL(for url: URL, accountID: String?) async throws -> URL
    func saveImage(_ data: Data, for url: URL, accountID: String?) async throws -> URL
    func dirSizeInBytes(accountID: String?) async -> Int64
    func clearDirectory(accountID: String?) async throws
    func removeImage(for url: URL, accountID: String?) async throws -> Bool
}
