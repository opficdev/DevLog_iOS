//
//  WebPageRepository.swift
//  DevLog
//
//  Created by 최윤진 on 2/8/26.
//

protocol WebPageRepository {
    func fetch() async throws -> [WebPageMetadata]
    func upsert(_ urlString: String) async throws -> WebPageMetadata
    func delete(_ urlString: String) async throws
}
