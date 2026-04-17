//
//  WidgetPlaceholderCard.swift
//  DevLogWidget
//
//  Created by opfic on 4/15/26.
//

import SwiftUI

struct WidgetPlaceholderCard: View {
    let title: String
    let message: String

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.secondary.opacity(0.12))
            .overlay {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .overlay(alignment: .topLeading) {
                Text(title)
                    .font(.headline)
                    .padding(12)
            }
    }
}
