//
//  FetchPushSettingsUseCase.swift
//  Domain
//
//  Created by 최윤진 on 1/25/26.
//

public protocol FetchPushSettingsUseCase {
    func execute() async throws -> PushNotificationSettings
}
