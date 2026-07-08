//
//  WebPageMetadataService.swift
//  Data
//
//  Created by opfic on 5/14/26.
//

import Foundation

public protocol WebPageMetadataService {
    func fetchMetadata(from urlString: String, accountID: String?) async throws -> WebPageMetadataResponse
    func removeCachedImage(for urlString: String, accountID: String?) async
    func cachedImageURL(for urlString: String, accountID: String?) async throws -> URL
}
