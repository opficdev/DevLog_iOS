//
//  FetchWebPagesUseCase.swift
//  DevLogDomain
//
//  Created by 최윤진 on 2/9/26.
//

public protocol FetchWebPagesUseCase {
    func execute(_ query: String) async throws -> [WebPage]
}
