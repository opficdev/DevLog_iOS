//
//  RecentActivityCard.swift
//  ProfileTab
//
//  Created by opfic on 9/24/26.
//

import SwiftUI
import PresentationShared

// 최근 활동 카드
struct RecentActivityCard: View {
    @Bindable var store: StoreOf<ProfileFeature>
    @ScaledMetric(relativeTo: .largeTitle) private var labelWidth = CGFloat(34)
    let onSelectTodo: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "profile_recent_title", bundle: PresentationResources.bundle))
                .font(.title3.bold())

            Group {
                if store.isRecentTodosLoading && store.recentTodos.isEmpty {
                    LoadingView()
                        .frame(maxWidth: .infinity, minHeight: 80)
                } else if store.recentTodos.isEmpty {
                    Text(String(localized: "profile_recent_empty", bundle: PresentationResources.bundle))
                        .font(.callout)
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 80)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(store.recentTodos.enumerated()), id: \.element.id) { index, todo in
                            Button {
                                onSelectTodo(todo.id)
                            } label: {
                                HStack(spacing: 12) {
                                    RecentTodoRow(todo: todo)
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.textTertiary)
                                }
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .todoDetailPreview(todoId: todo.id)
                            .padding(.vertical, 8)

                            if index < store.recentTodos.count - 1 {
                                Divider()
                                    .padding(.leading, labelWidth + 12)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct RecentTodoRow: View {
    @ScaledMetric(relativeTo: .largeTitle) private var labelWidth = CGFloat(34)
    let todo: RecentTodoItem

    var body: some View {
        let category = TodoCategoryItem(from: todo.category)
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(category.color)
                .frame(width: labelWidth, height: labelWidth)
                .overlay {
                    Image(systemName: category.symbolName)
                        .foregroundStyle(Color.white)
                        .font(.title3)
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if todo.isPinned {
                        Image(systemName: "star.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                    Text(todo.title)
                        .foregroundStyle(Color.primary)
                        .font(.headline)
                        .lineLimit(1)
                    Text("#\(todo.number)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.gray)
                        .fixedSize(horizontal: true, vertical: false)
                }

                HStack(spacing: 6) {
                    Text(category.localizedName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(category.color)

                    RelativeTimeText(date: todo.updatedAt)
                }

                if !todo.tags.isEmpty {
                    TagList(todo.tags, lineLimit: 1)
                }
            }
        }
    }
}
