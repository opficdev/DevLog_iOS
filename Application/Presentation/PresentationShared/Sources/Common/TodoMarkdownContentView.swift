//
//  TodoMarkdownContentView.swift
//  PresentationShared
//
//  Created by opfic on 3/25/26.
//

import SwiftUI
import Domain

struct TodoMarkdownContentView: View {
    @State private var tabBarHeight = CGFloat.zero

    let content: String
    let referenceItems: [Int: TodoReferenceItem]
    var onOpenTodoID: ((String) -> Void)?

    var body: some View {
        MarkdownRendererView(
            markdown: content,
            references: rendererReferences,
            obscuredBottomInset: tabBarHeight,
            onOpenReferenceID: onOpenTodoID
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.container, edges: ignoredSafeAreaEdges)
        .onAppear { updateTabBarHeight() }
    }

    private var ignoredSafeAreaEdges: Edge.Set {
        if #available(iOS 26.0, *) { return .bottom }

        return []
    }

    private var rendererReferences: [Int: MarkdownRendererReference] {
        referenceItems.mapValues { item in
            MarkdownRendererReference(
                referenceID: item.id,
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

    @MainActor
    private func updateTabBarHeight() {
        guard #available(iOS 26.0, *) else { return }

        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }

        tabBarHeight = window?.rootViewController?.visibleTabBarHeight ?? .zero
    }
}
