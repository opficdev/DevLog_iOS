//
//  FetchPushNotificationDataUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 1/24/26.
//

final class FetchPushNotificationSettingsUseCaseImpl: FetchPushSettingsUseCase {
    let repository: PushNotificationRepository

    init(_ repository: PushNotificationRepository) {
        self.repository = repository
    }

    func execute() async throws -> PushNotificationSettings {
        async let enabledValue = repository.fetchPushNotificationEnabled()
        async let componentsValue = repository.fetchPushNotificationTime()

        let (enabled, components) = try await (enabledValue, componentsValue)

        return PushNotificationSettings(
            isEnabled: enabled,
            scheduledTime: components
        )
    }
}
