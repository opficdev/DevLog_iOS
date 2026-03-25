//
//  String.swift
//  DevLog
//
//  Created by opfic on 5/19/25.
//

import Foundation

extension String {
    private static let todoReferencePattern = #"^([ \t]*)-[ \t]+refs[ \t]+#(\d+)[ \t]*$"#

    var todoReferenceNumbers: [Int] {
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

    func replacingTodoReferenceLines(using todoIDsByNumber: [Int: String]) -> String {
        split(separator: "\n", omittingEmptySubsequences: false)
            .map { line in
                let lineString = String(line)
                guard
                    let lineComponents = lineString.todoReferenceLineComponents,
                    let todoID = todoIDsByNumber[lineComponents.number]
                else {
                    return lineString
                }

                return "\(lineComponents.leadingWhitespace)- refs [#\(lineComponents.number)](devlog://todo/\(todoID))"
            }
            .joined(separator: "\n")
    }

    private var todoReferenceLineComponents: (leadingWhitespace: String, number: Int)? {
        guard let expression = try? NSRegularExpression(pattern: Self.todoReferencePattern) else {
            return nil
        }

        let range = NSRange(startIndex..., in: self)
        guard
            let match = expression.firstMatch(in: self, options: [], range: range),
            match.range == range,
            let leadingWhitespaceRange = Range(match.range(at: 1), in: self),
            let numberRange = Range(match.range(at: 2), in: self),
            let number = Int(self[numberRange])
        else {
            return nil
        }

        return (String(self[leadingWhitespaceRange]), number)
    }
}
