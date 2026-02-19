//
//  Error+.swift
//  DevLog
//
//  Created by 최윤진 on 11/29/25.
//

import Foundation

enum AuthError: Error {
    case notAuthenticated
    case failedToUnlinkLastProvider
    case unsupportedProvider
}

enum FirestoreError: Error, LocalizedError {
    case dataNotFound(_ key: String)

    var errorDescription: String? {
        switch self {
        case .dataNotFound(let key):
            return "\(key)가 Firestore에서 존재하지 않음"
        }
    }
}

enum UIError: Error {
    case notFoundTopViewController
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
