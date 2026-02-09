//
//  DeleteWebPageUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 2/9/26.
//

protocol DeleteWebPageUseCase {
    var repository: WebPageRepository { get }
    func execute(_ urlString: String) async throws
}
