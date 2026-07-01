//
//  ObserveAuthSessionUseCase.swift
//  Domain
//
//  Created by 최윤진 on 12/31/25.
//

import Combine

public protocol ObserveAuthSessionUseCase {
    func observe() -> AnyPublisher<Bool, Never>
}
