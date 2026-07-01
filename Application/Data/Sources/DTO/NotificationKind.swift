//
//  NotificationKind.swift
//  Data
//
//  Created by opfic on 6/28/25.
//

import Foundation
import Domain

public enum NotificationKind: String, Codable {
    case info
    case warning
    case success
    case error
}
