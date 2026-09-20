//
//  TodoCategoryGridLayout.swift
//  HomeTab
//
//  Created by opfic on 9/20/26.
//

import SwiftUI

struct TodoCategoryGridLayout: Layout {
    let columnCount: Int
    let itemWidth: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = proposal.width ?? itemWidth * CGFloat(columnCount)
        let spacing = spacing(for: width)
        let rowHeights = rowHeights(subviews: subviews)
        let rowSpacing = spacing * CGFloat(max(0, rowHeights.count - 1))

        return CGSize(
            width: width,
            height: spacing + rowHeights.reduce(0, +) + rowSpacing
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let spacing = spacing(for: bounds.width)
        let rowHeights = rowHeights(subviews: subviews)
        var currentY = bounds.minY + spacing

        for rowIndex in rowHeights.indices {
            let rowStartIndex = rowIndex * columnCount
            let rowEndIndex = min(rowStartIndex + columnCount, subviews.count)

            for itemIndex in rowStartIndex..<rowEndIndex {
                let columnIndex = itemIndex - rowStartIndex
                let centerX = bounds.minX
                    + spacing
                    + itemWidth / 2
                    + CGFloat(columnIndex) * (itemWidth + spacing)
                subviews[itemIndex].place(
                    at: CGPoint(x: centerX, y: currentY),
                    anchor: .top,
                    proposal: ProposedViewSize(width: itemWidth, height: nil)
                )
            }

            currentY += rowHeights[rowIndex] + spacing
        }
    }

    private func spacing(for width: CGFloat) -> CGFloat {
        max(0, (width - itemWidth * CGFloat(columnCount)) / CGFloat(columnCount + 1))
    }

    private func rowHeights(subviews: Subviews) -> [CGFloat] {
        stride(from: 0, to: subviews.count, by: columnCount).map { rowStartIndex in
            let rowEndIndex = min(rowStartIndex + columnCount, subviews.count)

            return (rowStartIndex..<rowEndIndex).reduce(0) { height, itemIndex in
                max(
                    height,
                    subviews[itemIndex].sizeThatFits(
                        ProposedViewSize(width: itemWidth, height: nil)
                    ).height
                )
            }
        }
    }
}
