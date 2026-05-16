//
//  ObserveUnreadPushCountUseCase.swift
//  DevLogDomain
//
//  Created by opfic on 3/17/26.
//

import Combine

public protocol ObserveUnreadPushCountUseCase {
    func observe() throws -> AnyPublisher<Int, Error>
}
