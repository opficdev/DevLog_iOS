//
//  WidgetDeepLink.swift
//  WidgetCore
//
//  Created by opfic on 4/30/26.
//

import Foundation

public enum WidgetDeepLink {
    public enum Destination: Equatable {
        case today
        case profile
        case todo(String)
    }

    public static let scheme = "DevLog"
    public static let todayTodoHost = "today"
    public static let heatmapHost = "profile"
    public static let todoIDQueryName = "todoId"

    public static var todayTodoURL: URL? {
        url(host: todayTodoHost)
    }

    public static func todoURL(id: String) -> URL? {
        guard !id.isEmpty else { return nil }

        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = todayTodoHost
        urlComponents.queryItems = [URLQueryItem(name: todoIDQueryName, value: id)]
        return urlComponents.url
    }

    public static var heatmapURL: URL? {
        url(host: heatmapHost)
    }

    public static func destination(for url: URL) -> Destination? {
        guard url.scheme?.lowercased() == scheme.lowercased(),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.path.isEmpty,
              let host = components.host?.lowercased() else { return nil }

        switch host {
        case todayTodoHost:
            let queryItems = components.queryItems ?? []
            if queryItems.isEmpty { return .today }
            guard queryItems.count == 1,
                  queryItems[0].name == todoIDQueryName,
                  let id = queryItems[0].value,
                  !id.isEmpty else { return nil }
            return .todo(id)
        case heatmapHost:
            guard components.queryItems == nil else { return nil }
            return .profile
        default:
            return nil
        }
    }

    private static func url(host: String) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        return urlComponents.url
    }
}
