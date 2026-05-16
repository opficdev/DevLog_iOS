//
//  TogglePushNotificationReadUseCase.swift
//  DevLogDomain
//
//  Created by opfic on 2/13/26.
//

public protocol TogglePushNotificationReadUseCase {
    func execute(_ todoId: String) async throws
}
