//
//  PushNotificationRoute.swift
//  DevLog
//
//  Created by opfic on 3/8/26.
//

import Foundation
import Combine

enum AppRoute: Equatable, Identifiable {
    case todoDetail(String)

    var id: String {
        switch self {
        case .todoDetail(let todoID):
            return "todo:\(todoID)"
        }
    }
}

final class PushNotificationRoute {
    static let shared = PushNotificationRoute()

    var publisher: AnyPublisher<AppRoute, Never> {
        subject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    private let subject = CurrentValueSubject<AppRoute?, Never>(nil)

    private init() { }

    func handlePushTap(userInfo: [AnyHashable: Any]) {
        guard let todoID = extractTodoID(from: userInfo) else { return }
        subject.send(.todoDetail(todoID))
    }

    func clear() {
        subject.send(nil)
    }

    private func extractTodoID(from userInfo: [AnyHashable: Any]) -> String? {
        if let todoID = userInfo["todoId"] as? String, !todoID.isEmpty {
            return todoID
        }

        if let todoID = userInfo["todoID"] as? String, !todoID.isEmpty {
            return todoID
        }

        return nil
    }
}
