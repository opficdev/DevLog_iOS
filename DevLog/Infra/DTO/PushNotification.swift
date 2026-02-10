//
//  PushNotification.swift
//  DevLog
//
//  Created by opfic on 6/28/25.
//

import Foundation

struct PushNotification: Identifiable {
    let id: String
    let title: String
    let body: String
    let receivedAt: Date
    var isRead: Bool
    let todoID: String
}
