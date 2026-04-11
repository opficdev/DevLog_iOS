//
//  UnlinkAuthProviderUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 2/12/26.
//

protocol UnlinkAuthProviderUseCase {
    func execute(_ provider: AuthProvider) async throws
}
