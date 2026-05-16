//
//  UpsertStatusMessageUseCase.swift
//  DevLogDomain
//
//  Created by 최윤진 on 1/10/26.
//

public protocol UpsertStatusMessageUseCase {
    func execute(_ message: String) async throws
}
