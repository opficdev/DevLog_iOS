//
//  UpdatePushSettingsUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 1/25/26.
//

protocol UpdatePushSettingsUseCase {
    func execute(_ settings: PushNotificationSettings) async throws
}
