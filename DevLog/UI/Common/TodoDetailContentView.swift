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
    let referenceItems: [Int: TodoReference]
    var number: Int?
    var activityLabel: String?
    var onOpenTodoID: ((String) -> Void)?

    var body: some View {
        ZStack {
            Color(.secondarySystemBackground).ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    if let activityLabel {
                        HStack {
                            Text(activityLabel)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(.systemGray4))
                                )
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
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
