//
//  AuthDataRepository.swift
//  DevLogDomain
//
//  Created by 최윤진 on 1/5/26.
//

public protocol AuthDataRepository {
    /// 현재 로그인한 프로바이더를 가져옵니다
    func fetchCurrentProvider() async throws -> AuthProvider?
    
    /// 연결된 모든 프로바이더 목록을 가져옵니다
    func fetchAllProviders() async throws -> [AuthProvider]
    
    /// 특정 프로바이더를 계정에 연결합니다
    func linkProvider(_ provider: AuthProvider) async throws -> Bool
    
    /// 특정 프로바이더를 계정에서 해제합니다
    func unlinkProvider(_ provider: AuthProvider) async throws
}
