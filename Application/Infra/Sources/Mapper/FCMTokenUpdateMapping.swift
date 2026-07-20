//
//  FCMTokenUpdateMapping.swift
//  Infra
//
//  Created by opfic on 7/20/26.
//

import Data

extension FCMTokenUpdate {
    var firestoreData: [String: Any] {
        [
            FCMTokenFieldKey.fcmToken.rawValue: fcmToken,
            FCMTokenFieldKey.pushLanguageCode.rawValue: code.rawValue
        ]
    }
}

private enum FCMTokenFieldKey: String {
    case fcmToken
    case pushLanguageCode
}
