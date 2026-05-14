//
//  SystemTodoCategoryItem.swift
//  DevLog
//
//  Created by opfic on 3/30/26.
//

import SwiftUI

public struct SystemTodoCategoryItem: Identifiable, Hashable {
    public let systemTodoCategory: SystemTodoCategory

    init(from systemTodoCategory: SystemTodoCategory) {
        self.systemTodoCategory = systemTodoCategory
    }

    public var id: String { systemTodoCategory.rawValue }

    public var symbolName: String {
        switch systemTodoCategory {
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

    public var localizedName: String {
        switch systemTodoCategory {
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

    public var color: UIColor {
        switch systemTodoCategory {
        case .issue: return .systemRed
        case .feature: return .systemGreen
        case .improvement: return .systemCyan
        case .review: return .systemOrange
        case .test: return .systemPurple
        case .doc: return .systemYellow
        case .research: return .systemTeal
        case .etc: return .systemGray
        }
    }
}
