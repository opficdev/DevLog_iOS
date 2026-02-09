//
//  AddWebPageUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 2/8/26.
//

protocol AddWebPageUseCase {
    var repository: WebPageRepository { get }
    func execute(_ urlString: String) async throws -> WebPage
}
