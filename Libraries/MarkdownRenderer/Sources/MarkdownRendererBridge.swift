//
//  MarkdownRendererBridge.swift
//  MarkdownRenderer
//
//  Created by opfic on 7/25/26.
//

import CoreGraphics
import Foundation

enum MarkdownRendererBridge {
    struct RenderPayload: Equatable {
        let markdown: String
        let references: [Int: MarkdownRendererReference]
        let colorScheme: String
        let languageCode: String
        let fontSize: CGFloat
        var tracksContentHeight = false

        var javaScriptValue: [String: Any] {
            let referenceValues = references.reduce(
                into: [String: [String: String]]()
            ) { values, element in
                values[String(element.key)] = element.value.javaScriptValue
            }

            return [
                "markdown": markdown,
                "references": referenceValues,
                "colorScheme": colorScheme,
                "languageCode": languageCode,
                "fontSize": Double(fontSize),
                "tracksContentHeight": tracksContentHeight
            ]
        }
    }

    enum JavaScriptMessage: Equatable {
        enum Name: String, CaseIterable {
            case reference
            case externalLink
            case contentHeight
        }

        case reference(Int)
        case externalLink(String)
        case contentHeight(CGFloat)

        init?(name: String, body: Any) {
            guard
                let name = Name(rawValue: name),
                let payload = body as? [String: Any]
            else {
                return nil
            }

            switch name {
            case .contentHeight:
                guard
                    let height = Self.number(from: payload["height"]),
                    height.doubleValue.isFinite,
                    0 < height.doubleValue
                else {
                    return nil
                }

                self = .contentHeight(CGFloat(height.doubleValue))

            case .reference:
                guard
                    let number = Self.number(from: payload["number"]),
                    number.doubleValue.isFinite,
                    number.doubleValue.rounded(.towardZero) == number.doubleValue,
                    Double(Int.min) <= number.doubleValue,
                    number.doubleValue <= Double(Int.max)
                else {
                    return nil
                }

                self = .reference(number.intValue)

            case .externalLink:
                guard let url = payload["url"] as? String else {
                    return nil
                }

                self = .externalLink(url)
            }
        }

        private static func number(from value: Any?) -> NSNumber? {
            guard
                let number = value as? NSNumber,
                CFGetTypeID(number) != CFBooleanGetTypeID()
            else {
                return nil
            }

            return number
        }
    }
}
