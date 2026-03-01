//
//  TodoInfoSheetView.swift
//  DevLog
//
//  Created by 최윤진 on 3/2/26.
//

import SwiftUI

struct TodoInfoSheetView: View {
    let dueDate: Date?
    let tags: [String]
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 32) {
                    VStack {
                        HStack {
                            Text("마감일")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
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
                    VStack {
                        HStack {
                            Text("태그")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
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
