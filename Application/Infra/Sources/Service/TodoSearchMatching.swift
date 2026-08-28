//
//  TodoSearchMatching.swift
//  Infra
//
//  Created by opfic on 8/28/26.
//

import Data

enum TodoSearchMatching {
    static func matches(
        _ todo: TodoResponse,
        keyword: String,
        numberKeyword: String? = nil
    ) -> Bool {
        let numberKeyword = numberKeyword ?? normalizedNumberKeyword(from: keyword) ?? keyword
        if keyword.hasPrefix("#"),
           1 < keyword.count,
           "#\(todo.number)".localizedCaseInsensitiveContains(numberKeyword) {
            return true
        }
        return todo.title.localizedCaseInsensitiveContains(keyword)
            || todo.content.localizedCaseInsensitiveContains(keyword)
            || todo.tags.contains { $0.localizedCaseInsensitiveContains(keyword) }
    }

    static func normalizedNumberKeyword(from keyword: String) -> String? {
        guard keyword.hasPrefix("#") else { return nil }
        let digits = keyword.dropFirst()
        guard !digits.isEmpty, digits.allSatisfy(\.isNumber) else { return nil }
        let normalizedDigits = digits.drop(while: { $0 == "0" })
        return "#\(normalizedDigits.isEmpty ? "0" : String(normalizedDigits))"
    }
}
