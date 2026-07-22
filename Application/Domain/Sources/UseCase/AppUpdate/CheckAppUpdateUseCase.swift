//
//  CheckAppUpdateUseCase.swift
//  Domain
//
//  Created by opfic on 7/22/26.
//

public protocol CheckAppUpdateUseCase {
    func execute() async throws -> Bool
}
