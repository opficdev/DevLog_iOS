//
//  MarkdownRendererURLPolicy.swift
//  PresentationShared
//
//  Created by opfic on 7/25/26.
//

import Foundation

enum MarkdownRendererURLPolicy {
    static func externalURL(from value: String) -> URL? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let components = URLComponents(string: trimmedValue),
            let scheme = components.scheme?.lowercased()
        else {
            return nil
        }

        switch scheme {
        case "http", "https":
            guard components.host?.isEmpty == false else { return nil }

        case "mailto":
            guard !components.path.isEmpty else { return nil }

        default:
            return nil
        }

        return components.url
    }

    static func allowsRendererNavigation(
        _ url: URL,
        indexURL: URL
    ) -> Bool {
        guard url.isFileURL else { return false }

        return url.standardizedFileURL.path == indexURL.standardizedFileURL.path
    }
}
