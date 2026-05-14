//
//  TodoInfoSheetView.swift
//  DevLog
//
//  Created by 최윤진 on 3/2/26.
//

import SwiftUI
import DevLogDomain
import DevLogPresentation

struct TodoInfoSheetView: View {
    let createdAt: Date
    let completedAt: Date?
    let dueDate: Date?
    let tags: [String]
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 32) {
                    VStack(alignment: .leading) {
                        Text(String(localized: "todo_info_created_at"))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                            Text(createdAt.formatted(date: .abbreviated, time: .omitted))
                            Spacer()
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.blue)
                        )
                        Divider()
                    }
                    VStack(alignment: .leading) {
                        Text(String(localized: "todo_info_due_date"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text(
                                dueDate?
                                    .formatted(date: .abbreviated, time: .omitted)
                                ?? String(localized: "todo_info_no_due_date")
                            )
                            .foregroundStyle(dueDate == nil ? .secondary : .primary)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.tertiarySystemFill))
                        )
                        Divider()
                    }
                    VStack(alignment: .leading) {
                        Text(String(localized: "todo_info_completed_at"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text(
                                completedAt?
                                    .formatted(date: .abbreviated, time: .omitted)
                                ?? String(localized: "todo_info_not_completed")
                            )
                            .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.green)
                        )
                        Divider()
                    }
                    VStack(alignment: .leading) {
                        Text(String(localized: "todo_tags"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Divider()
                        if !tags.isEmpty {
                            TagList(tags)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .toolbar {
                ToolbarLeadingButton {
                    onClose()
                }
            }
        }
    }
}
