//
//  TodoInfoSheetView.swift
//  DevLog
//
//  Created by 최윤진 on 3/2/26.
//

import SwiftUI

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
                        Text("생성일")
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
                        Text("마감일")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text(
                                dueDate?
                                    .formatted(date: .abbreviated, time: .omitted)
                                ?? "마감일 없음"
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
                        Text("완료일")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text(
                                completedAt?
                                    .formatted(date: .abbreviated, time: .omitted)
                                ?? "완료하지 않음"
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
                        Text("태그")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Divider()
                        if !tags.isEmpty {
                            TagLayout {
                                ForEach(tags, id: \.self) { tag in
                                    Tag(tag, isEditing: false)
                                }
                            }
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
