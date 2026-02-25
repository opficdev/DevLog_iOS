//
//  FetchPushNotificationQueryUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 2/25/26.
//

final class FetchPushNotificationQueryUseCaseImpl: FetchPushNotificationQueryUseCase {
    private let repository: UserPreferencesRepository

    init(_ repository: UserPreferencesRepository) {
        self.repository = repository
    }

    func execute() -> PushNotificationQuery {
        PushNotificationQuery(
            sortOrder: repository.pushNotificationSortOrder(),
            timeFilter: repository.pushNotificationTimeFilter(),
            unreadOnly: repository.pushNotificationUnreadOnly(),
            pageSize: 20
        )
    }
}
