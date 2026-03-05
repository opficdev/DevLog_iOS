//
//  View+.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import SwiftUI

extension View {
    @ViewBuilder
    func onScrollOffsetChange(action: @escaping (CGFloat) -> Void) -> some View {
        if #available(iOS 18, *) {
            self.onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y + geo.contentInsets.top
            } action: { _, newOffset in
                action(newOffset)
            }
        } else {
            self
        }
    }

    @ViewBuilder
    func adaptiveButtonStyle(
        shape: some Shape = .capsule,
        color: Color = .clear)
    -> some View {
        if #available(iOS 26.0, *) {
            self.foregroundStyle(Color(.label))
                .padding(8)
                .glassEffect(.regular.tint(color), in: shape)
        } else {
            self.foregroundStyle(Color(.label))
                .padding(8)
                .background {
                    Group {
                        if color == .clear {
                            shape
                                .fill(.ultraThinMaterial)
                        } else {
                            shape
                                .fill(color)
                        }
                    }
                    .overlay {
                        shape
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
                }
        }
    }
}
