//
//  DataLayerError.swift
//  Data
//
//  Created by opfic on 3/11/26.
//

import Foundation
import Core

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

public enum DataLayerError: Error {
    case notAuthenticated
    case linkCredentialAlreadyInUse
}
