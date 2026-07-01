//
//  UndoDeleteWebPageUseCase.swift
//  Domain
//
//  Created by opfic on 3/16/26.
//

public protocol UndoDeleteWebPageUseCase {
    func execute(_ id: String) async throws
}
