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
    struct Cache {
        var maxWidth: CGFloat = 0
        var rows: [Row] = []
    }

    var lineLimit: Int?
    var maxWidth: CGFloat?
    var verticalSpacing: CGFloat
    var horizontalSpacing: CGFloat

    init(
        verticalSpacing: CGFloat = 8,
        horizontalSpacing: CGFloat = 8
    ) {
        self.verticalSpacing = verticalSpacing
        self.horizontalSpacing = horizontalSpacing
    }

    init(
        lineLimit: Int,
        maxWidth: CGFloat,
        verticalSpacing: CGFloat = 8,
        horizontalSpacing: CGFloat = 8
    ) {
        self.lineLimit = lineLimit
        self.maxWidth = maxWidth
        self.verticalSpacing = verticalSpacing
        self.horizontalSpacing = horizontalSpacing
    }

    func makeCache(subviews: Subviews) -> Cache {
        Cache()
    }

    func updateCache(
        _ cache: inout Cache,
        subviews: Subviews,
        proposal: ProposedViewSize
    ) {
        let width = effectiveMaxWidth(
            proposalWidth: proposal.width,
            fallbackWidth: 0,
            forcedWidth: maxWidth
        )
        if cache.maxWidth != width {
            cache.maxWidth = width
            cache.rows = computeRows(maxWidth: width, subviews: subviews)
        } else if cache.rows.isEmpty {
            cache.rows = computeRows(maxWidth: width, subviews: subviews)
        }
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        updateCache(&cache, subviews: subviews, proposal: proposal)
        let rows = limitedRows(cache.rows)
        let height = rows.reduce(0) { $0 + $1.maxHeight } + CGFloat(max(0, rows.count - 1)) * verticalSpacing
        let rowsWidth = rows.map { $0.width }.max() ?? 0
        let width = (proposal.width ?? 0) > 0 ? (proposal.width ?? 0) : rowsWidth
        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        let width = effectiveMaxWidth(
            proposalWidth: proposal.width,
            fallbackWidth: bounds.width,
            forcedWidth: maxWidth
        )
        if cache.maxWidth != width {
            cache.maxWidth = width
            cache.rows = computeRows(maxWidth: width, subviews: subviews)
        }
        let rows = limitedRows(cache.rows)
        let allowedIndices = Set(rows.flatMap { $0.indices })
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

        let hiddenPosition = CGPoint(x: bounds.maxX + 10000, y: bounds.maxY + 10000)
        for index in subviews.indices where !allowedIndices.contains(index) {
            subviews[index].place(
                at: hiddenPosition,
                proposal: ProposedViewSize(width: 0, height: 0)
            )
        }
    }

    private func effectiveMaxWidth(
        proposalWidth: CGFloat?,
        fallbackWidth: CGFloat,
        forcedWidth: CGFloat?
    ) -> CGFloat {
        if let forcedWidth, forcedWidth > 0 {
            return forcedWidth
        }
        if let proposalWidth, proposalWidth > 0 {
            return proposalWidth
        }
        if fallbackWidth > 0 {
            return fallbackWidth
        }
        return .infinity
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
            currentRow.width = max(currentRow.width, currentWidth - horizontalSpacing)
        }

        if !currentRow.indices.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    private func limitedRows(_ rows: [Row]) -> [Row] {
        guard let lineLimit, 0 < lineLimit else {
            return rows
        }
        return Array(rows.prefix(lineLimit))
    }

    struct Row {
        var indices: [Int] = []
        var maxHeight: CGFloat = 0
        var width: CGFloat = 0
    }
}
