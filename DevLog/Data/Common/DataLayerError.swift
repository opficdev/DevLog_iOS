//
//  DataLayerError.swift
//  DevLog
//
//  Created by opfic on 3/11/26.
//

import Foundation

enum AuthError: Error {
    case notAuthenticated
    case failedToUnlinkLastProvider
    case unsupportedProvider
}

enum DataError: Error {
    case invalidData(context: String)

    private static let logger = Logger(category: "DataError")

    static func invalidData(
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
