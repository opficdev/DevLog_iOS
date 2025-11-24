//
//  EmailFetchError.swift
//  DevLog
//
//  Created by 최윤진 on 11/2/25.
//

import Foundation

enum EmailFetchError: Error, Equatable {
    case emailNotFound
    case emailMismatch
}
