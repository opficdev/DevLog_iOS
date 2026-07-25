//
//  TodoDetailContentView.swift
//  PresentationShared
//
//  Created by opfic on 3/2/26.
//

import SwiftUI
import Domain

struct TodoDetailContentView: View {
    @ScaledMetric(relativeTo: .title3) private var fontSize = 20
    let title: String
    let content: String
    let referenceItems: [Int: TodoReferenceItem]
    var number: Int
    var onOpenTodoID: ((String) -> Void)?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 10) {
                ScrollView(.horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(title)
                        Text("#\(number)")
                            .foregroundStyle(.gray)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .lineLimit(1)
                    .font(.title3.bold())
                }
                .frame(height: fontSize + 10)
                .scrollIndicators(.hidden)
                .contentMargins(16, for: .scrollContent)
                Divider()
                TodoMarkdownContentView(
                    content: content,
                    referenceItems: referenceItems,
                    onOpenTodoID: onOpenTodoID
                )
            }
        }
    }
}
