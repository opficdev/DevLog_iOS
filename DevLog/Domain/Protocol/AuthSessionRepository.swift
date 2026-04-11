//
//  AuthSessionRepository.swift
//  DevLog
//
//  Created by 최윤진 on 12/30/25.
//

import Combine

protocol AuthSessionRepository {
    func observeSignedIn() -> AnyPublisher<Bool, Never>
}
