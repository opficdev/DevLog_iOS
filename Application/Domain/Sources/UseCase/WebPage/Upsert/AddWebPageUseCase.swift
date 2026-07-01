//
//  AddWebPageUseCase.swift
//  Domain
//
//  Created by 최윤진 on 2/8/26.
//

public protocol AddWebPageUseCase {
    func execute(_ urlString: String) async throws
}
