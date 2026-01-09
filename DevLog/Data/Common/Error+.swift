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

enum FirestoreError: Error {
    case dataNotFound
}
