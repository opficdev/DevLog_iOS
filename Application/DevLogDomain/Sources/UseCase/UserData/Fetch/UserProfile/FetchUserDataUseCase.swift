//
//  FetchUserDataUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 1/10/26.
//

public protocol FetchUserDataUseCase {
    func execute() async throws -> UserProfile
}
