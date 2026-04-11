//
//  AddWebPageUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 2/8/26.
//

protocol AddWebPageUseCase {
    func execute(_ urlString: String) async throws
}
