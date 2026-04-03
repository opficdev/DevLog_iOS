//
//  TodoDetailContentView.swift
//  DevLog
//
//  Created by opfic on 3/2/26.
//

import SwiftUI
import MarkdownUI

struct TodoDetailContentView: View {
    let title: String
    let content: String
    let referenceItems: [Int: TodoReferenceItem]
    var number: Int?
    var onOpenTodoID: ((String) -> Void)?

    var body: some View {
        ZStack {
            Color(.secondarySystemBackground).ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(title)
                        if let number {
                            Text("#\(number)")
                                .foregroundStyle(.gray)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        Spacer()
                    }
                    .font(.title3.bold())
                    .padding(.horizontal)
                    Divider()
                    TodoMarkdownContentView(
                        content: content,
                        referenceItems: referenceItems,
                        onOpenTodoID: onOpenTodoID
                    )
                        .padding(.horizontal)
                }
            }
        }
    }
}
