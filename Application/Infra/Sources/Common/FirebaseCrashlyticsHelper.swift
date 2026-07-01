//
//  FirebaseCrashlyticsHelper.swift
//  Infra
//
//  Created by opfic on 6/16/26.
//

import FirebaseCrashlytics
import Foundation
import Nexa

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

    enum RESTKey: String {
        case statusCode = "restStatusCode"
        case errorMessage = "restErrorMessage"
    }

    static func userInfo(
        for nsError: NSError,
        error: Error,
        metadata: [String: String]
    ) -> [String: Any] {
        var userInfo: [String: Any] = [
            NSUnderlyingErrorKey: nsError,
            Key.underlyingType.rawValue: String(describing: type(of: error)),
            Key.underlyingDomain.rawValue: nsError.domain,
            Key.underlyingCode.rawValue: nsError.code
        ]

        restMetadata(for: error).forEach {
            userInfo[$0.key] = $0.value
        }

        metadata.forEach {
            userInfo[$0.key] = $0.value
        }

        return userInfo
    }

    static func restMetadata(for error: Error) -> [String: String] {
        guard let error = error as? NXError else { return [:] }

        switch error {
        case let .invalidStatus(statusCode, data),
             let .server(statusCode, data, underlying: _):
            var metadata = [
                RESTKey.statusCode.rawValue: String(statusCode)
            ]

            if let message = restErrorMessage(from: data) {
                metadata[RESTKey.errorMessage.rawValue] = message
            }

            return metadata
        default:
            return [:]
        }
    }

    private static func restErrorMessage(from data: Data?) -> String? {
        struct RESTErrorBody: Decodable {
            let message: String?
        }

        guard let data else { return nil }
        return try? JSONDecoder().decode(RESTErrorBody.self, from: data).message
    }
}
