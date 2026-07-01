//
//  UpdatePushNotificationQueryUseCaseImpl.swift
//  Domain
//
//  Created by 최윤진 on 2/25/26.
//

import Core

public final class UpdatePushNotificationQueryUseCaseImpl: UpdatePushNotificationQueryUseCase {
    private let repository: UserPreferencesRepository

    init(_ repository: UserPreferencesRepository) {
        self.repository = repository
    }

    public func execute(_ query: PushNotificationQuery) {
        repository.setPushNotificationSortOrder(query.sortOrder)
        repository.setPushNotificationTimeFilter(query.timeFilter)
        repository.setPushNotificationUnreadOnly(query.unreadOnly)
    }
}
