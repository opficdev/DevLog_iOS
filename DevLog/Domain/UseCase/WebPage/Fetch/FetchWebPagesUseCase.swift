//
//  FetchWebPagesUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 2/9/26.
//

protocol FetchWebPagesUseCase {
    var repository: WebPageRepository { get }
    func execute() async throws -> [WebPage]
}
