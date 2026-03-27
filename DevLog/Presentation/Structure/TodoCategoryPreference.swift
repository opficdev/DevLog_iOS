//
//  TodoCategoryPreference.swift
//  DevLog
//
//  Created by 최윤진 on 1/2/26.
//

struct TodoCategoryPreference: Identifiable, Equatable {
    var id: String { category.id }
    let category: TodoCategory
    var isVisible: Bool
}
