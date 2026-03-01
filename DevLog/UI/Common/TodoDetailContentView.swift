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
    var activityLabel: String?

    var body: some View {
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
                Text(title)
                    .font(.title3.bold())
                    .padding(.horizontal)
                Divider()
                Markdown(content)
                    .padding(.horizontal)
            }
        }
    }
}
