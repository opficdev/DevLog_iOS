//
//  NotificationKind.swift
//  DevLogData
//
//  Created by opfic on 6/28/25.
//

import Foundation
import DevLogDomain

public enum NotificationKind: String, Codable {
    case info
    case warning
    case success
    case error
}
