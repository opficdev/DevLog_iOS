//
//  Error+.swift
//  DevLog
//
//  Created by 최윤진 on 11/29/25.
//

import Foundation

enum AuthError: Error {
    case notAuthenticated
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
