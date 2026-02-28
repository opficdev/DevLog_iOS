//
//  TodoDTO.swift
//  DevLog
//
//  Created by 최윤진 on 12/14/25.
//

import Foundation
import FirebaseFirestore

struct TodoRequest: Dictionaryable {
    let id: String
    let isPinned: Bool
    let isCompleted: Bool
    let isChecked: Bool
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let dueDate: Date?
    let tags: [String]
    let kind: TodoKind

}

struct TodoResponse: Decodable {
    @DocumentID var id: String?
    let isPinned: Bool
    let isCompleted: Bool
    let isChecked: Bool
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let dueDate: Date?
    let tags: [String]
    let kind: String

    init?(from snapshot: QueryDocumentSnapshot) {
        self.init(documentID: snapshot.documentID, data: snapshot.data())
    }

    init?(from snapshot: DocumentSnapshot) {
        guard let data = snapshot.data() else { return nil }
        self.init(documentID: snapshot.documentID, data: data)
    }

    private init?(documentID: String, data: [String: Any]) {
        guard
            let id = documentID as String?,
            let isPinned = data["isPinned"] as? Bool,
            let isCompleted = data["isCompleted"] as? Bool,
            let isChecked = data["isChecked"] as? Bool,
            let title = data["title"] as? String,
            let content = data["content"] as? String,
            let createdAtTimestamp = data["createdAt"] as? Timestamp,
            let updatedAtTimestamp = data["updatedAt"] as? Timestamp,
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
        self.createdAt = createdAtTimestamp.dateValue()
        self.updatedAt = updatedAtTimestamp.dateValue()
        if let dueDateTimestamp = data["dueDate"] as? Timestamp {
            self.dueDate = dueDateTimestamp.dateValue()
        } else {
            self.dueDate = nil
        }
        self.tags = tags
        self.kind = kind
    }

}
