//
//  FetchPushNotificationQueryUseCaseImpl.swift
//  DevLogDomain
//
//  Created by 최윤진 on 2/25/26.
//

import DevLogCore

public final class FetchPushNotificationQueryUseCaseImpl: FetchPushNotificationQueryUseCase {
    private let repository: UserPreferencesRepository

    init(_ repository: UserPreferencesRepository) {
        self.repository = repository
    }

    public func execute() -> PushNotificationQuery {
        PushNotificationQuery(
            sortOrder: repository.pushNotificationSortOrder(),
            timeFilter: repository.pushNotificationTimeFilter(),
            unreadOnly: repository.pushNotificationUnreadOnly(),
            pageSize: 20
        )
    }
}
