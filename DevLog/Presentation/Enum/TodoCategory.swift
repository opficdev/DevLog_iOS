//
//  TodoCategory.swift
//  DevLog
//
//  Created by opfic on 5/29/25.
//

import SwiftUI

enum TodoCategory: String, Identifiable, CaseIterable, Codable {
    case issue          // 이슈
    case feature        // 신규 기능
    case improvement    // 개선/리팩터링
    case review         // 코드/문서 리뷰
    case test           // 테스트/QA
    case doc            // 문서화
    case research       // 리서치/학습
    case etc            // 기타

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .issue: return "exclamationmark.triangle"
        case .feature: return "sparkles"
        case .improvement: return "arrow.triangle.2.circlepath"
        case .review: return "eye"
        case .test: return "checkmark.shield"
        case .doc: return "doc.text"
        case .research: return "magnifyingglass"
        case .etc: return "ellipsis"
        }
    }
    
    var localizedName: String {
        switch self {
        case .issue: return NSLocalizedString("todo_category_issue", comment: "Todo category: Issue")
        case .feature: return NSLocalizedString("todo_category_feature", comment: "Todo category: Feature")
        case .improvement: return NSLocalizedString("todo_category_improvement", comment: "Todo category: Improvement")
        case .review: return NSLocalizedString("todo_category_review", comment: "Todo category: Review")
        case .test: return NSLocalizedString("todo_category_test", comment: "Todo category: Test")
        case .doc: return NSLocalizedString("todo_category_doc", comment: "Todo category: Documentation")
        case .research: return NSLocalizedString("todo_category_research", comment: "Todo category: Research")
        case .etc: return NSLocalizedString("todo_category_etc", comment: "Todo category: Etc")
        }
    }
    
    var color: Color {
        switch self {
        case .issue: return Color.red
        case .feature: return Color.green
        case .improvement: return Color.cyan
        case .review: return Color.orange
        case .test: return Color.purple
        case .doc: return Color.yellow
        case .research: return Color.teal
        case .etc: return Color.gray
        }
    }
}
