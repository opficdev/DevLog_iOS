//
//  UpdatePushSettingsUseCaseImpl.swift
//  DevLog
//
//  Created by 최윤진 on 1/25/26.
//

final class UpdatePushSettingsUseCaseImpl: UpdatePushSettingsUseCase {
    private let repository: PushNotificationRepository

    init(_ repository: PushNotificationRepository) {
        self.repository = repository
    }

    func execute(_ settings: PushNotificationSettings) async throws {
        try await repository.updatePushNotificationSettings(settings)
    }
}
