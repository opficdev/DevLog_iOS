//
//  String.swift
//  DevLog
//
//  Created by opfic on 5/19/25.
//

import Foundation

public extension String {
    private static let todoReferencePattern = #"^([ \t]*)-[ \t]+refs[ \t]+#(\d+)[ \t]*$"#

    public var todoReferenceNumbers: [Int] {
        guard
            let expression = try? NSRegularExpression(
                pattern: Self.todoReferencePattern,
                options: [.anchorsMatchLines]
            )
        else {
            return []
        }

        let range = NSRange(startIndex..., in: self)
        let matches = expression.matches(in: self, options: [], range: range)
        var numbers = [Int]()
        var seen = Set<Int>()

        for match in matches {
            guard
                let numberRange = Range(match.range(at: 2), in: self),
                let number = Int(self[numberRange]),
                !seen.contains(number)
            else {
                continue
            }

            seen.insert(number)
            numbers.append(number)
        }

        return numbers
    }
}
