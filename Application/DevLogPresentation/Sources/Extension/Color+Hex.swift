//
//  Color+Hex.swift
//  DevLog
//
//  Created by opfic on 3/30/26.
//

import SwiftUI
import DevLogDomain
import DevLogData

extension Color {
    static var randomValue: Color {
        Color(
            red: Double(Int.random(in: 0...255)) / 255,
            green: Double(Int.random(in: 0...255)) / 255,
            blue: Double(Int.random(in: 0...255)) / 255
        )
    }

    init?(hexString: String) {
        let trimmedHex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedHex = trimmedHex.hasPrefix("#") ? String(trimmedHex.dropFirst()) : trimmedHex

        guard sanitizedHex.count == 6,
              let hexValue = Int(sanitizedHex, radix: 16) else {
            return nil
        }

        let red = Double((hexValue >> 16) & 0xFF) / 255
        let green = Double((hexValue >> 8) & 0xFF) / 255
        let blue = Double(hexValue & 0xFF) / 255

        self.init(red: red, green: green, blue: blue)
    }

    var hexValue: String? {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        let redValue = Int(round(red * 255))
        let greenValue = Int(round(green * 255))
        let blueValue = Int(round(blue * 255))

        return String(format: "#%02X%02X%02X", redValue, greenValue, blueValue)
    }
}
