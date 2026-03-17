//
//  ObserveUnreadPushCountUseCaseImpl.swift
//  DevLog
//
//  Created by opfic on 3/17/26.
//

import Combine

final class ObserveUnreadPushCountUseCaseImpl: ObserveUnreadPushCountUseCase {
    private let repository: PushNotificationRepository

    init(_ repository: PushNotificationRepository) {
        self.repository = repository
    }

    func execute() throws -> AnyPublisher<Int, Error> {
        try repository.observeUnreadPushCount()
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
