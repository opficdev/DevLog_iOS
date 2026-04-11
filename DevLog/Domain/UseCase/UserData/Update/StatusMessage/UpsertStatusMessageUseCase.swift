//
//  UpsertStatusMessageUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 1/10/26.
//

protocol UpsertStatusMessageUseCase {
    func execute(_ message: String) async throws
}
