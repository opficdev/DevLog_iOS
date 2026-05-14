//
//  WidgetDeepLink.swift
//  DevLog
//
//  Created by opfic on 4/30/26.
//

import Foundation

public enum WidgetDeepLink {
    public static let scheme = "DevLog"
    public static let todayTodoHost = "today"
    public static let heatmapHost = "profile"

    public static var todayTodoURL: URL? {
        url(host: todayTodoHost)
    }

    public static var heatmapURL: URL? {
        url(host: heatmapHost)
    }

    private static func url(host: String) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        return urlComponents.url
    }
}
