//
//  Todo.swift
//  Domain
//
//  Created by opfic on 5/29/25.
//

import Foundation

public struct Todo: Hashable {
    public let id: String
    public var goalID: String?
    public var isPinned: Bool      //  해당 할 일이 상단에 고정되어 있는지 여부
    public var isCompleted: Bool   //  해당 할 일의 완료 여부
    public var isChecked: Bool     //  해당 할 일의 체크 여부
    public var number: Int         //  사용자에게 노출되는 Todo 번호
    public var title: String       //  할 일의 제목
    public var content: String //  할 일의 설명
    public var createdAt: Date     //  할 일 생성 날짜
    public var updatedAt: Date     //  할 일 수정 날짜
    public var completedAt: Date?  //  할 일 완료 날짜
    public var deletedAt: Date?    //  할 일 삭제 날짜
    public var dueDate: Date?      //  할 일의 마감 날짜 (선택 사항)
    public var tags: [String]      //  할 일에 연결된 태그들
    public var category: TodoCategory  //  할 일의 종류

    public init(
        id: String,
        isPinned: Bool,
        isCompleted: Bool,
        isChecked: Bool,
        number: Int,
        title: String,
        content: String,
        createdAt: Date,
        updatedAt: Date,
        completedAt: Date?,
        deletedAt: Date?,
        dueDate: Date?,
        tags: [String],
        category: TodoCategory
    ) {
        self.init(
            id: id,
            isPinned: isPinned,
            isCompleted: isCompleted,
            isChecked: isChecked,
            number: number,
            title: title,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt,
            deletedAt: deletedAt,
            dueDate: dueDate,
            tags: tags,
            category: category,
            goalID: nil
        )
    }

    public init(
        id: String,
        isPinned: Bool,
        isCompleted: Bool,
        isChecked: Bool,
        number: Int,
        title: String,
        content: String,
        createdAt: Date,
        updatedAt: Date,
        completedAt: Date?,
        deletedAt: Date?,
        dueDate: Date?,
        tags: [String],
        category: TodoCategory,
        goalID: String?
    ) {
        self.id = id
        self.goalID = goalID
        self.isPinned = isPinned
        self.isCompleted = isCompleted
        self.isChecked = isChecked
        self.number = number
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.deletedAt = deletedAt
        self.dueDate = dueDate
        self.tags = tags
        self.category = category
    }
}
