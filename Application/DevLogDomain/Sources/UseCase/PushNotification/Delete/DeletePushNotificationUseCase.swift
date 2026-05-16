//
//  DeletePushNotificationUseCase.swift
//  DevLogDomain
//
//  Created by 최윤진 on 2/10/26.
//

public protocol DeletePushNotificationUseCase {
    func execute(_ notificationID: String) async throws
}
