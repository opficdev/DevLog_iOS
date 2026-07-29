//
//  PushNotificationResponse.swift
//  Data
//
//  Created by 최윤진 on 2/10/26.
//

import Foundation
import Domain

public struct PushNotificationResponse {
    private struct LegacyValue {
        let title: String
        let body: String
    }

    @available(*, deprecated, message: "todoTitle 기반 알림을 사용한다.")
    public struct Legacy {
        public let title: String
        public let body: String

        public init(title: String, body: String) {
            self.title = title
            self.body = body
        }
    }

    public let id: String
    public let todoTitle: String?
    private let legacyValue: LegacyValue?
    @available(*, deprecated, message: "todoTitle 기반 알림을 사용한다.")
    public var legacy: Legacy? {
        legacyValue.map { Legacy(title: $0.title, body: $0.body) }
    }
    public let receivedAt: Date
    public let isRead: Bool
    public let todoId: String
    public let todoCategory: TodoCategoryResponse

    public init(
        id: String,
        todoTitle: String?,
        receivedAt: Date,
        isRead: Bool,
        todoId: String,
        todoCategory: TodoCategoryResponse
    ) {
        self.id = id
        self.todoTitle = todoTitle
        self.legacyValue = nil
        self.receivedAt = receivedAt
        self.isRead = isRead
        self.todoId = todoId
        self.todoCategory = todoCategory
    }

    @available(*, deprecated, message: "todoTitle 기반 알림을 사용한다.")
    public init(
        id: String,
        legacy: Legacy,
        receivedAt: Date,
        isRead: Bool,
        todoId: String,
        todoCategory: TodoCategoryResponse
    ) {
        self.id = id
        self.todoTitle = nil
        self.legacyValue = LegacyValue(title: legacy.title, body: legacy.body)
        self.receivedAt = receivedAt
        self.isRead = isRead
        self.todoId = todoId
        self.todoCategory = todoCategory
    }
}
