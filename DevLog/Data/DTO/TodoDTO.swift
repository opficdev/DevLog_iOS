//
//  TodoDTO.swift
//  DevLog
//
//  Created by 최윤진 on 12/14/25.
//

import Foundation

struct TodoRequest: Encodable {
    let id: String
    let isPinned: Bool
    let isCompleted: Bool
    let isChecked: Bool
    let number: Int?
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let completedAt: Date?
    let dueDate: Date?
    let tags: [String]
    let kind: TodoKind

}

struct TodoResponse {
    let id: String
    let isPinned: Bool
    let isCompleted: Bool
    let isChecked: Bool
    let number: Int
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let completedAt: Date?
    let dueDate: Date?
    let tags: [String]
    let kind: String
}
