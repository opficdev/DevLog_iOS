//
//  TogglePushNotificationReadUseCase.swift
//  DevLog
//
//  Created by opfic on 2/13/26.
//

protocol TogglePushNotificationReadUseCase {
    func execute(_ todoID: String) async throws
}
