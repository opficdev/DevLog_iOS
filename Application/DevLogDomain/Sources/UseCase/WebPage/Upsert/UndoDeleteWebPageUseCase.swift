//
//  UndoDeleteWebPageUseCase.swift
//  DevLogDomain
//
//  Created by opfic on 3/16/26.
//

public protocol UndoDeleteWebPageUseCase {
    func execute(_ urlString: String) async throws
}
