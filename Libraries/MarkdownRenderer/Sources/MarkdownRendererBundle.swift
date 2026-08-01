//
//  MarkdownRendererBundle.swift
//  PresentationShared
//
//  Created by opfic on 7/25/26.
//

import Foundation

enum MarkdownRendererBundle {
    static var indexURL: URL? {
        indexURL(in: Bundle(for: MarkdownRendererBundleToken.self))
    }

    static func indexURL(in bundle: Bundle) -> URL? {
        bundle.url(
            forResource: "index",
            withExtension: "html",
            subdirectory: "MarkdownRenderer"
        )
    }
}

private final class MarkdownRendererBundleToken {}
