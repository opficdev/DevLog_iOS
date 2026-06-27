//
//  DeleteWebPageUseCase.swift
//  DevLogDomain
//
//  Created by 최윤진 on 2/9/26.
//

public protocol DeleteWebPageUseCase {
    func execute(id: String, urlString: String) async throws
}
