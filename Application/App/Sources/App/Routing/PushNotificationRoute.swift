//
//  PushNotificationRoute.swift
//  DevLog
//
//  Created by opfic on 3/8/26.
//

import Foundation
import Combine

final class PushNotificationRoute {
    static let shared = PushNotificationRoute()

    func observe() -> AnyPublisher<String, Never> {
        subject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    private let subject = CurrentValueSubject<String?, Never>(nil)

    private init() { }

    func handlePushTap(userInfo: [AnyHashable: Any]) {
        guard let todoId = extractTodoId(from: userInfo) else { return }
        subject.send(todoId)
    }

    func clear() {
        subject.send(nil)
    }

    private func extractTodoId(from userInfo: [AnyHashable: Any]) -> String? {
        guard let todoId = userInfo["todoId"] as? String, !todoId.isEmpty else {
            return nil
        }
        return todoId
    }
}
