//
//  PushMessagingServiceImpl.swift
//  Infra
//
//  Created by opfic on 5/15/26.
//

import Foundation
import Data
import FirebaseMessaging
import UserNotifications

final class PushMessagingServiceImpl: NSObject, PushMessagingService {
    private enum CrashlyticsError {
        static let domain = "DevLogInfra.PushMessagingServiceImpl"

        enum Code: Int {
            case fetchFCMToken = 1
        }
    }

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
            FirebaseCrashlyticsHelper.record(
                error,
                domain: "\(CrashlyticsError.domain).\(CrashlyticsError.Code.fetchFCMToken)",
                code: CrashlyticsError.Code.fetchFCMToken.rawValue
            )
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
