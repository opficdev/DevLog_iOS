//
//  FCMTokenUpdate.swift
//  Data
//
//  Created by opfic on 7/20/26.
//

public struct FCMTokenUpdate: Equatable, Sendable {
    public let fcmToken: String
    public let code: PushLanguageCode

    public init(
        fcmToken: String,
        code: PushLanguageCode
    ) {
        self.fcmToken = fcmToken
        self.code = code
    }
}

public enum PushLanguageCode: String, Equatable, Sendable {
    case korean = "ko"
    case english = "en"

    public init(identifier: String?) {
        let languageCode = identifier?
            .split(whereSeparator: { $0 == "-" || $0 == "_" })
            .first?
            .lowercased()

        self = languageCode == Self.english.rawValue ? .english : .korean
    }
}
