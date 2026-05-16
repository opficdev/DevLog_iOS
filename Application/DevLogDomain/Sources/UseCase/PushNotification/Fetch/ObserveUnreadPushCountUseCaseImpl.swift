//
//  ObserveUnreadPushCountUseCaseImpl.swift
//  DevLogDomain
//
//  Created by opfic on 3/17/26.
//

import Combine

public final class ObserveUnreadPushCountUseCaseImpl: ObserveUnreadPushCountUseCase {
    private let repository: PushNotificationRepository

    init(_ repository: PushNotificationRepository) {
        self.repository = repository
    }

    public func observe() throws -> AnyPublisher<Int, Error> {
        try repository.observeUnreadPushCount()
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
