//
//  TodoDocumentMapper.swift
//  Infra
//
//  Created by opfic on 8/28/26.
//

import FirebaseFirestore
import Data

enum TodoDocumentFieldKey: String {
    case id
    case goalId
    case isPinned
    case isCompleted
    case isChecked
    case number
    case title
    case content
    case createdAt
    case updatedAt
    case completedAt
    case deletedAt
    case dueDate
    case tags
    case category
}

enum TodoDocumentMapper {
    static func makeDocumentData(
        from request: TodoRequest,
        encoder: Firestore.Encoder = .init()
    ) throws -> [String: Any] {
        var data = try encoder.encode(request)
        data.removeValue(forKey: TodoDocumentFieldKey.id.rawValue)
        if request.completedAt == nil {
            data[TodoDocumentFieldKey.completedAt.rawValue] = NSNull()
        }
        if request.deletedAt == nil {
            data[TodoDocumentFieldKey.deletedAt.rawValue] = NSNull()
        }
        if request.dueDate == nil {
            data[TodoDocumentFieldKey.dueDate.rawValue] = NSNull()
        }
        if request.goalId == nil {
            data[TodoDocumentFieldKey.goalId.rawValue] = FieldValue.delete()
        }
        return data
    }

    static func makeResponse(_ document: QueryDocumentSnapshot) -> TodoResponse? {
        makeResponse(documentID: document.documentID, data: document.data())
    }

    static func makeResponse(documentID: String, data: [String: Any]) -> TodoResponse? {
        guard
            let number = data[TodoDocumentFieldKey.number.rawValue] as? Int,
            let title = data[TodoDocumentFieldKey.title.rawValue] as? String,
            let createdAt = data[TodoDocumentFieldKey.createdAt.rawValue] as? Timestamp,
            let updatedAt = data[TodoDocumentFieldKey.updatedAt.rawValue] as? Timestamp,
            let category = data[TodoDocumentFieldKey.category.rawValue] as? String
        else {
            return nil
        }

        let completedAt = (data[TodoDocumentFieldKey.completedAt.rawValue] as? Timestamp)?.dateValue()
        let deletedAt = (data[TodoDocumentFieldKey.deletedAt.rawValue] as? Timestamp)?.dateValue()
        let dueDate = (data[TodoDocumentFieldKey.dueDate.rawValue] as? Timestamp)?.dateValue()
        return TodoResponse(
            id: documentID,
            isPinned: data[TodoDocumentFieldKey.isPinned.rawValue] as? Bool ?? false,
            isCompleted: data[TodoDocumentFieldKey.isCompleted.rawValue] as? Bool ?? (completedAt != nil),
            isChecked: data[TodoDocumentFieldKey.isChecked.rawValue] as? Bool ?? false,
            number: number,
            title: title,
            content: data[TodoDocumentFieldKey.content.rawValue] as? String ?? "",
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            completedAt: completedAt,
            deletedAt: deletedAt,
            dueDate: dueDate,
            tags: data[TodoDocumentFieldKey.tags.rawValue] as? [String] ?? [],
            category: .raw(category),
            goalId: data[TodoDocumentFieldKey.goalId.rawValue] as? String
        )
    }
}
