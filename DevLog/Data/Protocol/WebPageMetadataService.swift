//
//  WebPageMetadataService.swift
//  DevLog
//
//  Created by opfic on 5/14/26.
//

import Foundation

protocol WebPageMetadataService {
    func fetchMetadata(from urlString: String) async throws -> WebPageMetadataResponse
    func removeCachedImage(for urlString: String) async
    func cachedImageURL(for urlString: String) async throws -> URL
}
