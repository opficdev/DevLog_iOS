//
//  PushNotificationDecoder.swift
//  Infra
//
//  Created by opfic on 7/19/26.
//

import Data

enum PushNotificationDecoder {
    private enum FieldKey: String {
        case contentType
        case contentArguments
    }

    private enum ContentType: String {
        case todoDueTomorrow
    }

    private enum ArgumentKey: String {
        case todoTitle
    }

    static func decode(_ data: [String: Any]) -> PushNotificationResponse.Content? {
        guard let contentType = data[FieldKey.contentType.rawValue] as? String,
              let type = ContentType(rawValue: contentType) else {
            return nil
        }

        switch type {
        case .todoDueTomorrow:
            let contentArguments = data[FieldKey.contentArguments.rawValue] as? [String: Any]
            return .todoDueTomorrow(
                todoTitle: contentArguments?[ArgumentKey.todoTitle.rawValue] as? String
            )
        }
    }
}
