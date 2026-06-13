//
//  PushMessagingServiceImpl.swift
//  DevLogInfra
//
//  Created by opfic on 5/15/26.
//

import Foundation
import DevLogData
import FirebaseMessaging
import UserNotifications

final class PushMessagingServiceImpl: NSObject, PushMessagingService {
    private weak var delegate: PushMessagingServiceDelegate?

    func setDelegate(_ delegate: PushMessagingServiceDelegate?) {
        self.delegate = delegate
        Messaging.messaging().delegate = self
    }

    func setAPNSToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func isNotificationAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }

    func fetchFCMToken() async throws -> String? {
        do {
            return try await Messaging.messaging().token()
        } catch {
            if error.isMissingAPNSTokenForFCMToken {
                return nil
            }
            throw error
        }
    }
}

extension PushMessagingServiceImpl: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        delegate?.pushMessagingService(self, didReceiveRegistrationToken: fcmToken)
    }
}

private extension Error {
    var isMissingAPNSTokenForFCMToken: Bool {
        let nsError = self as NSError
        return nsError.domain == "com.google.fcm" && nsError.code == 505
    }
}
