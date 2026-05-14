//
//  DeleteWebPageUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 2/9/26.
//

public protocol DeleteWebPageUseCase {
    func execute(_ urlString: String) async throws
}
