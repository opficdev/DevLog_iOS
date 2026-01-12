//
//  TodoKindPreference.swift
//  DevLog
//
//  Created by 최윤진 on 1/2/26.
//

struct TodoKindPreference: Identifiable, Equatable {
    var id: String { kind.id }
    let kind: TodoKind
    var isVisible: Bool
}
