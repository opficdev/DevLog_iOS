//
//  DataLayerError.swift
//  Data
//
//  Created by opfic on 3/11/26.
//

import Foundation
import Core

public enum EmailError: Error, Equatable {
    case notFound
    case mismatch
    case githubEmailConflict

    public var code: String {
        switch self {
        case .mismatch:
            "email_mismatch"
        case .notFound:
            "email_not_found"
        case .githubEmailConflict:
            "github-email-changed-account-conflict"
        }
    }
}

public enum DataLayerError: Error {
    case notAuthenticated
    case linkCredentialAlreadyInUse
    case invalidData(context: String)

    private static let logger = Logger(category: "DataLayerError")

    public static func invalidData(
        _ context: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) -> DataLayerError {
        logger.error(
            "Invalid data: \(context)",
            file: file,
            function: function,
            line: line
        )
        return .invalidData(context: context)
    }
}
