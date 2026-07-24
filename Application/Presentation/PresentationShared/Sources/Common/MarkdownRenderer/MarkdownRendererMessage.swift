//
//  MarkdownRendererMessage.swift
//  PresentationShared
//
//  Created by opfic on 7/25/26.
//

import CoreGraphics
import Foundation

enum MarkdownRendererMessage: Equatable {
    enum Name: String, CaseIterable {
        case contentHeight
        case todoReference
        case externalLink
    }

    case contentHeight(CGFloat)
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
        case .contentHeight:
            guard
                let number = Self.number(from: payload["height"]),
                number.doubleValue.isFinite,
                0 < number.doubleValue
            else {
                return nil
            }

            self = .contentHeight(CGFloat(number.doubleValue))

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
