//
//  FetchUserDataUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 1/10/26.
//

protocol FetchUserDataUseCase {
    func execute() async throws -> UserProfile
}
