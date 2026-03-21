//
//  AuthSessionUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 12/31/25.
//

import Combine

protocol AuthSessionUseCase {
    var signedInPublisher: AnyPublisher<Bool, Never> { get }
}
