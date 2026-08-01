//
//  MarkdownRendererView.swift
//  MarkdownRenderer
//
//  Created by opfic on 8/1/26.
//

import SwiftUI

public struct MarkdownRendererView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale
    @Environment(\.openURL) private var openURL
    @ScaledMetric(relativeTo: .body) private var fontSize = 17

    private let markdown: String
    private let references: [Int: MarkdownRendererReference]
    private let obscuredBottomInset: CGFloat
    private let onOpenTodoID: ((String) -> Void)?

    public init(
        markdown: String,
        references: [Int: MarkdownRendererReference] = [:],
        obscuredBottomInset: CGFloat = .zero,
        onOpenTodoID: ((String) -> Void)? = nil
    ) {
        self.markdown = markdown
        self.references = references
        self.obscuredBottomInset = obscuredBottomInset
        self.onOpenTodoID = onOpenTodoID
    }

    public var body: some View {
        MarkdownWebView(
            markdown: markdown,
            references: references,
            colorScheme: colorScheme,
            languageCode: locale.language.languageCode?.identifier ?? "und",
            fontSize: fontSize,
            obscuredBottomInset: obscuredBottomInset,
            onOpenTodoID: onOpenTodoID,
            onOpenURL: { openURL($0) }
        )
    }
}
