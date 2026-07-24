//
//  TodoMarkdownContentView.swift
//  PresentationShared
//
//  Created by opfic on 3/25/26.
//

import SwiftUI
import Domain

struct TodoMarkdownContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @ScaledMetric(relativeTo: .body) private var fontSize = 17
    // 로직이 간단한 편이므로 TCA를 적용하지 않음
    @State private var contentHeight: CGFloat = 1

    let content: String
    let referenceItems: [Int: TodoReferenceItem]
    var onOpenTodoID: ((String) -> Void)?

    var body: some View {
        MarkdownRendererView(
            markdown: content,
            references: rendererReferences,
            colorScheme: colorScheme,
            fontSize: fontSize,
            contentHeight: $contentHeight,
            onOpenTodoID: onOpenTodoID,
            onOpenURL: { openURL($0) }
        )
        .frame(height: contentHeight)
    }

    private var rendererReferences: [Int: MarkdownRendererReference] {
        referenceItems.mapValues { item in
            MarkdownRendererReference(
                todoID: item.id,
                title: item.title,
                colorHex: item.category.color.hexValue ?? "#808080",
                iconDataURL: iconDataURL(for: item.category.symbolName)
            )
        }
    }

    private func iconDataURL(for symbolName: String) -> String? {
        let configuration = UIImage.SymbolConfiguration(
            pointSize: 11,
            weight: .bold
        )

        guard
            let image = UIImage(
                systemName: symbolName,
                withConfiguration: configuration
            )?.withTintColor(.white, renderingMode: .alwaysOriginal),
            let data = image.pngData()
        else {
            return nil
        }

        return "data:image/png;base64,\(data.base64EncodedString())"
    }
}
