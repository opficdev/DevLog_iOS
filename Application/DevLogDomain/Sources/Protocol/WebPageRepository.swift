//
//  WebPageRepository.swift
//  DevLog
//
//  Created by 최윤진 on 2/8/26.
//

public protocol WebPageRepository {
    func fetch(_ query: String) async throws -> [WebPage]
    func upsert(_ urlString: String) async throws
    func delete(_ urlString: String) async throws
    func undoDelete(_ urlString: String) async throws
}
