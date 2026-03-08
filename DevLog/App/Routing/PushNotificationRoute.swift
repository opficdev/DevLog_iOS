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
        case .todoDetail(let todoId):
            return "todo:\(todoId)"
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
        guard let todoId = extractTodoId(from: userInfo) else { return }
        subject.send(.todoDetail(todoId))
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
