//
//  PushNotificationResponse.swift
//  DevLog
//
//  Created by 최윤진 on 2/10/26.
//

import FirebaseFirestore

struct PushNotificationResponse: Decodable {
    @DocumentID var id: String?
    let title: String
    let body: String
    let receivedAt: Timestamp
    let isRead: Bool
    let todoID: String
    let todoKind: String
}
