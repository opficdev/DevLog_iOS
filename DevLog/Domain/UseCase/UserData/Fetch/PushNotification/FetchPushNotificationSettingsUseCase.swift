//
//  FetchPushSettingsUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 1/25/26.
//

protocol FetchPushSettingsUseCase {
    var repository: PushNotificationRepository { get }
    func execute() async throws -> PushNotificationSettings
}
