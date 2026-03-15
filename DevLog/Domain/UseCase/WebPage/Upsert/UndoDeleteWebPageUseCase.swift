//
//  UndoDeleteWebPageUseCase.swift
//  DevLog
//
//  Created by opfic on 3/16/26.
//

protocol UndoDeleteWebPageUseCase {
    func execute(_ urlString: String) async throws
}
