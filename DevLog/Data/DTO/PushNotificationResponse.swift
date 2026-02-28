//
//  PushNotificationResponse.swift
//  DevLog
//
//  Created by 최윤진 on 2/10/26.
//

import Foundation

struct PushNotificationResponse {
    let id: String?
    let title: String
    let body: String
    let receivedAt: Date
    let isRead: Bool
    let todoID: String
    let todoKind: String
}
