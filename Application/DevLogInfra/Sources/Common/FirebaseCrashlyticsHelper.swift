//
//  FirebaseCrashlyticsHelper.swift
//  DevLogInfra
//
//  Created by opfic on 6/16/26.
//

import FirebaseCrashlytics
import Foundation

enum FirebaseCrashlyticsHelper {
    static func record(
        _ error: Error,
        domain: String,
        code: Int,
        metadata: [String: String] = [:],
        logs: [String] = []
    ) {
        let nsError = error as NSError
        let report = NSError(
            domain: domain,
            code: code,
            userInfo: userInfo(for: nsError, error: error, metadata: metadata)
        )
        let crashlytics = Crashlytics.crashlytics()

        logs.forEach {
            crashlytics.log($0)
        }

        crashlytics.record(error: report)
    }
}

private extension FirebaseCrashlyticsHelper {
    enum Key: String {
        case underlyingType
        case underlyingDomain
        case underlyingCode
    }

    static func userInfo(
        for nsError: NSError,
        error: Error,
        metadata: [String: String]
    ) -> [String: Any] {
        var userInfo: [String: Any] = [
            Key.underlyingType.rawValue: String(describing: type(of: error)),
            Key.underlyingDomain.rawValue: nsError.domain,
            Key.underlyingCode.rawValue: nsError.code
        ]

        metadata.forEach {
            userInfo[$0.key] = $0.value
        }

        return userInfo
    }
}
