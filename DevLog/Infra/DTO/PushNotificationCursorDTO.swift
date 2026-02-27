//
//  PushNotificationCursorDTO.swift
//  DevLog
//
//  Created by 최윤진 on 2/27/26.
//

import FirebaseFirestore

struct PushNotificationCursorDTO {
    let receivedAt: Timestamp
    let documentID: String
}
