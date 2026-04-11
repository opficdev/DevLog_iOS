//
//  ObserveUnreadPushCountUseCase.swift
//  DevLog
//
//  Created by opfic on 3/17/26.
//

import Combine

protocol ObserveUnreadPushCountUseCase {
    func observe() throws -> AnyPublisher<Int, Error>
}
