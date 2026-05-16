//
//  DataLayerError.swift
//  DevLogData
//
//  Created by opfic on 3/11/26.
//

import AuthenticationServices
import Foundation
import DevLogCore

public enum EmailFetchError: Error, Equatable {
    case emailNotFound
    case emailMismatch

    public var code: String {
        switch self {
        case .emailMismatch:
            "email_mismatch"
        case .emailNotFound:
            "email_not_found"
        }
    }
}

public enum DataError: Error {
    case invalidData(context: String)

    private static let logger = Logger(category: "DataError")

    public static func invalidData(
        _ context: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) -> DataError {
        logger.error(
            "Invalid data: \(context)",
            file: file,
            function: function,
            line: line
        )
        return .invalidData(context: context)
    }
}

public extension Error {
    var isSocialLoginCancelled: Bool {
        switch self {
        case let authError as ASAuthorizationError:
            return authError.code == .canceled
        case let webAuthError as ASWebAuthenticationSessionError:
            return webAuthError.code == .canceledLogin
        default:
            let nsError = self as NSError
            return nsError.domain == "com.google.GIDSignIn" && nsError.code == -5
        }
    }
}
