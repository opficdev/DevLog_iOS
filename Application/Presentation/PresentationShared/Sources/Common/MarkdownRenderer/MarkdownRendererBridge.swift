//
//  MarkdownRendererBridge.swift
//  PresentationShared
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
                "fontSize": Double(fontSize)
            ]
        }
    }

    enum JavaScriptMessage: Equatable {
        enum Name: String, CaseIterable {
            case todoReference
            case externalLink
        }

        case todoReference(Int)
        case externalLink(String)

        init?(name: String, body: Any) {
            guard
                let name = Name(rawValue: name),
                let payload = body as? [String: Any]
            else {
                return nil
            }

            switch name {
            case .todoReference:
                guard
                    let number = Self.number(from: payload["number"]),
                    number.doubleValue.isFinite,
                    number.doubleValue.rounded(.towardZero) == number.doubleValue,
                    Double(Int.min) <= number.doubleValue,
                    number.doubleValue <= Double(Int.max)
                else {
                    return nil
                }

                self = .todoReference(number.intValue)

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
