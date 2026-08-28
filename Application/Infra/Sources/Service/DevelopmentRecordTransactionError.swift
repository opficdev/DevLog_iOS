//
//  DevelopmentRecordTransactionError.swift
//  Infra
//
//  Created by opfic on 8/28/26.
//

import Foundation

enum DevelopmentRecordTransactionError {
    static let draftConflictCode = 2

    static func make(_ context: String, code: Int = 1) -> NSError {
        NSError(
            domain: "DevelopmentRecordServiceImpl",
            code: code,
            userInfo: [NSLocalizedDescriptionKey: context]
        )
    }

    static func isDraftConflict(_ error: NSError) -> Bool {
        error.domain == "DevelopmentRecordServiceImpl" &&
        error.code == draftConflictCode
    }
}
