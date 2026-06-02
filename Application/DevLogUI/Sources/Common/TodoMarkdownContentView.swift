//
//  TodoMarkdownContentView.swift
//  DevLogUI
//
//  Created by opfic on 3/25/26.
//

import MarkdownUI
import SwiftUI
import DevLogPresentation

private enum TodoMarkdownSection: Equatable {
    case markdown(String)
    case reference(Int)
}

struct TodoMarkdownContentView: View {
    let content: String
    let referenceItems: [Int: TodoReferenceItem]
    var onOpenTodoID: ((String) -> Void)?

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            let sections = makeSections(from: content)
            ForEach(Array(zip(sections.indices, sections)), id: \.0) { _, section in
                switch section {
                case .markdown(let markdown):
                    if !markdown.isEmpty {
                        Markdown(markdown)
                    }
                case .reference(let number):
                    if let item = referenceItems[number] {
                        TodoReferenceRow(
                            item: item,
                            number: number,
                            onOpenTodoID: onOpenTodoID
                        )
                    } else {
                        Markdown("- refs #\(number)")
                    }
                }
            }
        }
    }

    private func makeSections(from content: String) -> [TodoMarkdownSection] {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var sections = [TodoMarkdownSection]()
        var markdownBuffer = [String]()

        func flushMarkdownBuffer() {
            guard !markdownBuffer.isEmpty else { return }
            sections.append(.markdown(markdownBuffer.joined(separator: "\n")))
            markdownBuffer.removeAll(keepingCapacity: true)
        }

        for line in lines {
            if let number = todoReferenceLineNumber(from: line) {
                flushMarkdownBuffer()
                sections.append(.reference(number))
            } else {
                markdownBuffer.append(line)
            }
        }

        flushMarkdownBuffer()
        return sections
    }

    private func todoReferenceLineNumber(from line: String) -> Int? {
        guard let expression = try? NSRegularExpression(pattern: #"^([ \t]*)-[ \t]+refs[ \t]+#(\d+)[ \t]*$"#) else {
            return nil
        }

        let range = NSRange(line.startIndex..., in: line)
        guard
            let match = expression.firstMatch(in: line, options: [], range: range),
            match.range == range,
            let numberRange = Range(match.range(at: 2), in: line),
            let number = Int(line[numberRange])
        else {
            return nil
        }

        return number
    }
}

private struct TodoReferenceRow: View {
    let item: TodoReferenceItem
    let number: Int
    var onOpenTodoID: ((String) -> Void)?

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Markdown("- refs")
            Button {
                onOpenTodoID?(item.id)
            } label: {
                HStack(alignment: .center, spacing: 8) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(item.category.color)
                        .frame(width: 18, height: 18)
                        .overlay {
                            Image(systemName: item.category.symbolName)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                        }

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(item.title)
                            .foregroundStyle(.blue)
                        Text("#\(number)")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: true, vertical: false)

                    }
                    .lineLimit(1)
                    .overlay(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(height: 1)
                            .offset(y: 1)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }
}
