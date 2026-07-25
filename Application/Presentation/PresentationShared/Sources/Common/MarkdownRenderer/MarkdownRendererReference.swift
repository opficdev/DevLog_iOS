//
//  MarkdownRendererReference.swift
//  PresentationShared
//
//  Created by opfic on 7/25/26.
//

import Foundation

struct MarkdownRendererReference: Equatable {
    let todoID: String
    let title: String
    let colorHex: String
    let iconDataURL: String?

    var javaScriptValue: [String: String] {
        [
            "title": title,
            "color": colorHex,
            "iconDataURL": iconDataURL ?? ""
        ]
    }
}
