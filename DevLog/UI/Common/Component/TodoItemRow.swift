//
//  TodoItemRow.swift
//  DevLog
//
//  Created by 최윤진 on 2/21/26.
//

import SwiftUI

struct TodoItemRow: View {
    @Environment(\.sceneWidth) private var sceneWidth
    private let item: TodoListItem

    init(_ item: TodoListItem) {
        self.item = item
    }

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle")
                .resizable()
                .frame(width: sceneWidth * 0.08, height: sceneWidth * 0.08)
                .foregroundStyle(item.isCompleted ? .green : .secondary)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    if item.isPinned {
                        Image(systemName: "star.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    }
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(Color(.label))
                        .lineLimit(1)
                    if let number = item.number {
                        Text("#\(number)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.gray)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                RelativeTimeText(date: item.updatedAt)
                if !item.tags.isEmpty {
                    TagList(item.tags, lineLimit: 1)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2.bold())
                .foregroundStyle(.gray)
        }
        .padding(.vertical, 12)
    }
}
