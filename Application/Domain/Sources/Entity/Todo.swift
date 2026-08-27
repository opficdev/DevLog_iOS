//
//  Todo.swift
//  Domain
//
//  Created by opfic on 5/29/25.
//

import Foundation

public struct Todo: Hashable {
    public let id: String
    public var goalId: String?      //  연결된 개발 목표 ID
    public var isPinned: Bool       //  상단에 고정되어 있는지 여부
    public var isCompleted: Bool    //  완료 여부
    public var isChecked: Bool      //  체크 여부
    public var number: Int          //  사용자에게 노출되는 Todo 번호
    public var title: String        //  제목
    public var content: String      //  설명
    public var createdAt: Date      //  생성 날짜
    public var updatedAt: Date      //  최근 수정 날짜
    public var completedAt: Date?   //  완료 날짜
    public var deletedAt: Date?     //  삭제 날짜
    public var dueDate: Date?       //  마감 날짜 (선택 사항)
    public var tags: [String]       //  연결된 태그들
    public var category: TodoCategory  // 종류

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
        goalId: String? = nil
    ) {
        self.id = id
        self.goalId = goalId
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
