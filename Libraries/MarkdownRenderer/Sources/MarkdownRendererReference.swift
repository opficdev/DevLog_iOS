//
//  MarkdownRendererReference.swift
//  MarkdownRenderer
//
//  Created by opfic on 7/25/26.
//

import Foundation

public struct MarkdownRendererReference: Equatable {
    let referenceID: String
    let title: String
    let colorHex: String
    let iconDataURL: String?

    public init(
        referenceID: String,
        title: String,
        colorHex: String,
        iconDataURL: String?
    ) {
        self.referenceID = referenceID
        self.title = title
        self.colorHex = colorHex
        self.iconDataURL = iconDataURL
    }

    var javaScriptValue: [String: String] {
        [
            "title": title,
            "color": colorHex,
            "iconDataURL": iconDataURL ?? ""
        ]
    }
}
