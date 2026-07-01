//
//  WebPageService.swift
//  Data
//
//  Created by opfic on 5/14/26.
//

import Foundation

public protocol WebPageService {
    func fetchWebPages(_ query: String) async throws -> [WebPageResponse]
    func upsertWebPage(_ request: WebPageRequest) async throws
    func deleteWebPage(_ id: String) async throws
    func undoDeleteWebPage(_ id: String) async throws
}
