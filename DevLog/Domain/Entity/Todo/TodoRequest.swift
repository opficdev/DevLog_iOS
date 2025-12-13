//
//  TodoRequest.swift
//  DevLog
//
//  Created by 최윤진 on 12/12/25.
//

import Foundation

struct TodoRequest: Encodable {
    let title: String
    let content: String
    let dueDate: Date?
    let tags: [String]
}
