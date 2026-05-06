//
//  TodoItemRow.swift
//  DevLog
//
//  Created by 최윤진 on 2/21/26.
//

import SwiftUI

struct TodoItemRow: View {
    private let labelWidth: CGFloat = UIFont.preferredFont(forTextStyle: .largeTitle).pointSize
    private let item: TodoListItem

    init(_ item: TodoListItem) {
        self.item = item
    }

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle")
                .resizable()
                .frame(width: labelWidth, height: labelWidth)
                .foregroundStyle(item.isCompleted ? .green : .secondary)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(Color(.label))
                        .lineLimit(1)
                    Text("#\(item.number)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.gray)
                        .fixedSize(horizontal: true, vertical: false)
                }
                HStack(spacing: 4) {
                    if item.isPinned {
                        Image(systemName: "star.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    }
                    RelativeTimeText(date: item.updatedAt)
                }
                .frame(height: UIFont.preferredFont(forTextStyle: .headline).lineHeight)
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
