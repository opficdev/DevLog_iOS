//
//  SystemTodoCategory+Presentation.swift
//  DevLog
//
//  Created by opfic on 3/29/26.
//

import SwiftUI

extension SystemTodoCategory: Identifiable {
    var id: String { rawValue }
}

extension SystemTodoCategory: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

extension SystemTodoCategory {
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
        case .issue: return .red
        case .feature: return .green
        case .improvement: return .cyan
        case .review: return .orange
        case .test: return .purple
        case .doc: return .yellow
        case .research: return .teal
        case .etc: return .gray
        }
    }
}
