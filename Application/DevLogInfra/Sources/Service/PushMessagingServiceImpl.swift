//
//  PushMessagingServiceImpl.swift
//  DevLogInfra
//
//  Created by opfic on 5/15/26.
//

import Foundation
import DevLogData
import FirebaseMessaging

final class PushMessagingServiceImpl: NSObject, PushMessagingService {
    private weak var delegate: PushMessagingServiceDelegate?

    func setDelegate(_ delegate: PushMessagingServiceDelegate?) {
        self.delegate = delegate
        Messaging.messaging().delegate = self
    }

    func setAPNSToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension PushMessagingServiceImpl: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        delegate?.pushMessagingService(self, didReceiveRegistrationToken: fcmToken)
    }
}
