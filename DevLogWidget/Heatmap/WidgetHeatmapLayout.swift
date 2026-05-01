//
//  WidgetHeatmapLayout.swift
//  DevLogWidget
//
//  Created by opfic on 4/28/26.
//

import SwiftUI

struct WidgetHeatmapLayout {
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let monthSpacing: CGFloat
    let monthTitleSpacing: CGFloat
    let showsMonthTitles: Bool

    init(
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        weekCounts: [Int],
        showsMonthTitles: Bool
    ) {
        self.showsMonthTitles = showsMonthTitles
        self.monthTitleSpacing = Self.resolvedMonthTitleSpacing(showsMonthTitles: showsMonthTitles)
        cellSize = Self.cellSize(
            availableHeight: availableHeight,
            showsMonthTitles: showsMonthTitles
        )
        cellSpacing = Self.baseCellSpacing
        monthSpacing = Self.monthSpacing(
            availableWidth: availableWidth,
            cellSize: cellSize,
            weekCounts: weekCounts,
            showsMonthTitles: showsMonthTitles
        )
    }

    var cellCornerRadius: CGFloat {
        max(2, cellSize * 0.2)
    }

    private static let baseCellSpacing: CGFloat = 3
    private static let baseMonthSpacing: CGFloat = 10
    private static let maxMonthSpacing: CGFloat = 26
    private static let baseMonthTitleSpacing: CGFloat = 4

    private static func resolvedMonthTitleSpacing(showsMonthTitles: Bool) -> CGFloat {
        // 월 제목을 표시하는 Medium에서만 제목과 셀 사이 간격을 확보한다.
        showsMonthTitles ? baseMonthTitleSpacing : 0
    }

    private static func sanitizedWeekCounts(_ weekCounts: [Int]) -> [Int] {
        // 빈 월이 있어도 0개 주차가 전체 컬럼 계산에 섞이지 않도록 제거한다.
        weekCounts.filter { 0 < $0 }
    }

    private static func totalColumns(in weekCounts: [Int]) -> Int {
        // 모든 월의 주차 수를 더해 실제 셀 컬럼 수를 구한다.
        max(weekCounts.reduce(0, +), 1)
    }

    private static func totalColumnSpacings(in weekCounts: [Int]) -> Int {
        // 각 월 내부에서 주차 컬럼 사이에 들어가는 spacing 개수를 합산한다.
        weekCounts.reduce(0) { partialResult, count in
            partialResult + max(count - 1, 0)
        }
    }

    private static func monthSpacingCount(in weekCounts: [Int]) -> Int {
        // 월과 월 사이 간격 개수는 표시되는 월 개수보다 하나 적다.
        max(weekCounts.count - 1, 0)
    }

    private static func cellSize(
        availableHeight: CGFloat,
        showsMonthTitles: Bool
    ) -> CGFloat {
        // 히트맵은 세로 7일 행이 고정이므로 높이를 기준으로 셀 크기를 결정한다.
        // Medium은 월 제목 1행을 같은 셀 높이로 추가해 총 8행 기준으로 계산한다.
        let verticalCellCount = showsMonthTitles ? 8 : 7
        // 날짜 셀 7행 사이의 세로 spacing 6개와 월 제목 spacing을 높이에서 제외한다.
        let verticalFixedHeight = resolvedMonthTitleSpacing(showsMonthTitles: showsMonthTitles)
            + baseCellSpacing * CGFloat(max(7 - 1, 0))
        return max(0, availableHeight - verticalFixedHeight) / CGFloat(verticalCellCount)
    }

    private static func extraWidth(
        availableWidth: CGFloat,
        cellSize: CGFloat,
        weekCounts: [Int]
    ) -> CGFloat {
        // 셀 크기는 높이 기준으로 고정하고, 남는 가로폭만 월 간격 계산에 사용한다.
        let sanitizedWeekCounts = sanitizedWeekCounts(weekCounts)
        // 전체 셀 컬럼과 월 내부 주차 spacing을 더해 기본 너비를 구한다.
        let contentWidth = cellSize * CGFloat(totalColumns(in: sanitizedWeekCounts))
            + baseCellSpacing * CGFloat(totalColumnSpacings(in: sanitizedWeekCounts))
        // 기본 너비보다 위젯이 넓을 때만 월 간격에 분배할 여유 폭이 생긴다.
        return max(0, availableWidth - contentWidth)
    }

    private static func monthSpacing(
        availableWidth: CGFloat,
        cellSize: CGFloat,
        weekCounts: [Int],
        showsMonthTitles: Bool
    ) -> CGFloat {
        // Medium의 3개월 사이 간격만 확장하고, 과한 벌어짐은 상한으로 제한한다.
        let sanitizedWeekCounts = sanitizedWeekCounts(weekCounts)
        let monthSpacingCount = monthSpacingCount(in: sanitizedWeekCounts)
        // Small은 한 달만 표시하므로 월 간격이 필요 없다.
        guard showsMonthTitles && 0 < monthSpacingCount else { return 0 }
        let extraWidth = extraWidth(
            availableWidth: availableWidth,
            cellSize: cellSize,
            weekCounts: sanitizedWeekCounts
        )
        // 남는 폭을 월 사이 간격에 균등 분배하되 기본값과 상한 사이로 제한한다.
        return min(max(extraWidth / CGFloat(monthSpacingCount), baseMonthSpacing), maxMonthSpacing)
    }
}
