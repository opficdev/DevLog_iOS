//
//  ObserveAuthSessionUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 12/31/25.
//

import Combine

protocol ObserveAuthSessionUseCase {
    var signedInPublisher: AnyPublisher<Bool, Never> { get }
}
