//
//  WebPageService.swift
//  DevLog
//
//  Created by opfic on 5/14/26.
//

import Foundation
import DevLogDomain
import DevLogDataDTO

public protocol WebPageService {
    func fetchWebPages(_ query: String) async throws -> [WebPageResponse]
    func upsertWebPage(_ request: WebPageRequest) async throws
    func deleteWebPage(_ urlString: String) async throws
    func undoDeleteWebPage(_ urlString: String) async throws
}
