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
            }
            TagLayout(lineLimit: 1) {
                ForEach(item.tags, id: \.self) { tagText in
                    Tag(tagText, isEditing: false)
                }
            }
        }
        .padding(.vertical, 5)
    }
}
