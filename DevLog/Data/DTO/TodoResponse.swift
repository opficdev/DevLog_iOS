//
//  TodoResponse.swift
//  DevLog
//
//  Created by 최윤진 on 11/23/25.
//

import Foundation
import FirebaseFirestore

struct TodoResponse: Decodable {
    @DocumentID var id: String?
    let isPinned: Bool
    let isCompleted: Bool
    let isChecked: Bool
    let title: String
    let content: String
    let createdAt: Timestamp
    let updatedAt: Timestamp
    let dueDate: Timestamp?
    let tags: [String]
    let kind: String

    init?(from snapshot: QueryDocumentSnapshot) {
        let data = snapshot.data()
        guard
            let id = snapshot.documentID as String?,
            let isPinned = data["isPinned"] as? Bool,
            let isCompleted = data["isCompleted"] as? Bool,
            let isChecked = data["isChecked"] as? Bool,
            let title = data["title"] as? String,
            let content = data["content"] as? String,
            let createdAt = data["createdAt"] as? Timestamp,
            let updatedAt = data["updatedAt"] as? Timestamp,
            let tags = data["tags"] as? [String],
            let kind = data["kind"] as? String else {
            return nil
        }
        self.id = id
        self.isPinned = isPinned
        self.isCompleted = isCompleted
        self.isChecked = isChecked
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.dueDate = data["dueDate"] as? Timestamp
        self.tags = tags
        self.kind = kind
    }

    func toDomain() -> Todo {
        Todo(
            id: self.id == nil ? UUID().uuidString : self.id!,
            isPinned: self.isPinned,
            isCompleted: self.isCompleted,
            isChecked: self.isChecked,
            title: self.title,
            content: self.content,
            createdAt: self.createdAt.dateValue(),
            updatedAt: self.updatedAt.dateValue(),
            dueDate: self.dueDate?.dateValue(),
            tags: self.tags,
            kind: TodoKind(rawValue: self.kind) ?? .etc
        )
    }
}
