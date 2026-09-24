//
//  View+IconStyle.swift
//  PresentationShared
//
//  Created by opfic on 9/24/26.
//

import SwiftUI

public extension View {
    func iconStyle<S: Shape>(
        color: Color,
        in shape: S
    ) -> some View {
        modifier(IconStyleModifier(color: color, shape: shape))
    }
}

private struct IconStyleModifier<S: Shape>: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let color: Color
    let shape: S

    func body(content: Content) -> some View {
        content
            .foregroundStyle(colorScheme == .dark ? Color.white : color)
            .background(
                colorScheme == .dark ? color : color.opacity(0.12),
                in: shape
            )
    }
}
