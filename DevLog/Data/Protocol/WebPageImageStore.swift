//
//  WebPageImageStore.swift
//  DevLog
//
//  Created by opfic on 5/14/26.
//

import Foundation

public protocol WebPageImageStore {
    func cachedImageURL(for url: URL) async throws -> URL
    func saveImage(_ data: Data, for url: URL) async throws -> URL
    func dirSizeInBytes() async -> Int64
    func clearDirectory() async throws
    func removeImage(for url: URL) async throws -> Bool
}
