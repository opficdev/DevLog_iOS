//
//  DeletePushNotificationUseCase.swift
//  DevLog
//
//  Created by 최윤진 on 2/10/26.
//

protocol DeletePushNotificationUseCase {
    func execute(_ notificationID: String) async throws
}
