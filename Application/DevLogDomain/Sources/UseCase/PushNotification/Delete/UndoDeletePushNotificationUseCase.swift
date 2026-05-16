//
//  UndoDeletePushNotificationUseCase.swift
//  DevLogDomain
//
//  Created by opfic on 3/16/26.
//

public protocol UndoDeletePushNotificationUseCase {
    func execute(_ notificationID: String) async throws
}
