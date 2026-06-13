//
//  NotificationName+.swift
//  DevLog
//
//  Created by opfic on 3/19/26.
//

import Foundation

extension Notification.Name {
    static let didRefreshFCMToken = Notification.Name("didRefreshFCMToken")
    static let didReceiveAPNSToken = Notification.Name("didReceiveAPNSToken")
    static let didRequestFCMTokenSync = Notification.Name("didRequestFCMTokenSync")
    static let didRequestRemoteNotificationRegistration = Notification.Name("didRequestRemoteNotificationRegistration")
    static let didRequestUserTimeZoneSync = Notification.Name("didRequestUserTimeZoneSync")
}
