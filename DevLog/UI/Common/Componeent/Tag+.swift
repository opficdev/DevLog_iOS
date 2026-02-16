//
//  Tag+.swift
//  DevLog
//
//  Created by 최윤진 on 2/6/26.
//

import SwiftUI

struct Tag: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var height: CGFloat = 0
    private let name: String
    private let isEditing: Bool
    private var action: (() -> Void)?

    init(_ name: String, isEditing: Bool, action: (() -> Void)? = nil) {
        self.name = name
        self.isEditing = isEditing
        self.action = action
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .foregroundStyle(.blue)
                .bold()
                .lineLimit(1)
                .fixedSize()
                .padding(.vertical, 4)
                .padding(.leading, 8)
                .padding(.trailing, isEditing ? 0 : 8)
                .background {
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                height = geo.size.height
                            }
                    }
                }

            if isEditing {
                Button {
                    action?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: height, height: height)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            .blue,
                            .black.opacity(colorScheme == .light ? 0 : 0.4)
                        )

                }
            }
        }
        .background {
            Capsule()
                .fill(.blue.opacity(0.2))
        }
    }
}

struct TagLayout: Layout {
    var lineLimit: Int?
    var verticalSpacing: CGFloat = 8
    var horizontalSpacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.maxHeight } + CGFloat(max(0, rows.count - 1)) * verticalSpacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var minY = bounds.minY

        for row in rows {
            var minX = bounds.minX

            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: minX, y: minY),
                    proposal: ProposedViewSize(size)
                )
                minX += size.width + horizontalSpacing
            }

            minY += row.maxHeight + verticalSpacing
        }
    }

    private func computeRows(
        maxWidth: CGFloat,
        subviews: Subviews
    ) -> [Row] {
        let availableWidth = maxWidth > 0 ? maxWidth : .infinity
        var rows: [Row] = []
        var currentRow = Row()
        var currentWidth: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)

            if currentWidth + size.width > availableWidth && !currentRow.indices.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
                currentWidth = 0
            }

            currentRow.indices.append(index)
            currentRow.maxHeight = max(currentRow.maxHeight, size.height)
            currentWidth += size.width + horizontalSpacing
        }

        if !currentRow.indices.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    private struct Row {
        var indices: [Int] = []
        var maxHeight: CGFloat = 0
    }
}
