//
//  PushMessagingService.swift
//  Data
//
//  Created by opfic on 5/15/26.
//

import Foundation

public protocol PushMessagingService: AnyObject {
    func setDelegate(_ delegate: PushMessagingServiceDelegate?)
    func setAPNSToken(_ deviceToken: Data)
    func isNotificationAuthorized() async -> Bool
    func fetchFCMToken() async throws -> String?
}

public protocol PushMessagingServiceDelegate: AnyObject {
    func pushMessagingService(_ service: PushMessagingService, didReceiveRegistrationToken fcmToken: String?)
}
