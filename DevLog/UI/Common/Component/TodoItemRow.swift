//
//  TodoItemRow.swift
//  DevLog
//
//  Created by 최윤진 on 2/21/26.
//

import SwiftUI

struct TodoItemRow: View {
    private let item: TodoListItem

    init(_ item: TodoListItem) {
        self.item = item
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    if item.isPinned {
                        Image(systemName: "star.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    }
                    if item.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                    }
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(Color(.label))
                        .lineLimit(1)
                }
                if !item.tags.isEmpty {
                    TagLayout(lineLimit: 1) {
                        ForEach(item.tags, id: \.self) { tagText in
                            Tag(tagText, isEditing: false)
                        }
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2.bold())
                .foregroundStyle(.gray)
        }
        .padding(.vertical, item.tags.isEmpty ? 20 : 4)
    }
}
