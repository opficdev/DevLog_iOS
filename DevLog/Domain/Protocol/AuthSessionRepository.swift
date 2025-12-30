//
//  AuthSessionRepository.swift
//  DevLog
//
//  Created by 최윤진 on 12/30/25.
//

import Combine

protocol AuthSessionRepository {
    var signedInPublisher: AnyPublisher<Bool, Never> { get }
    func setSession(_ signedIn: Bool)
}
