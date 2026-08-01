//
//  MarkdownRendererBundle.swift
//  MarkdownRenderer
//
//  Created by opfic on 7/25/26.
//

import Foundation

enum MarkdownRendererBundle {
    static let bundle = Bundle(for: MarkdownRendererBundleToken.self)

    static var indexURL: URL? {
        indexURL(in: bundle)
    }

    static func indexURL(in bundle: Bundle) -> URL? {
        bundle.url(
            forResource: "index",
            withExtension: "html"
        )
    }
}

private final class MarkdownRendererBundleToken {}
