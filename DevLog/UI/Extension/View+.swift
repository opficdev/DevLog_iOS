//
//  View+.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import SwiftUI

extension View {
    @ViewBuilder
    func adaptiveButtonStyle(_ color: Color? = nil) -> some View {
        if #available(iOS 26.0, *), color == nil {
            self.buttonStyle(.glass)
        } else {
            self.foregroundStyle(Color(.label))
                .font(.footnote)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .background {
                            Capsule()
                                .fill(color ?? Color.clear)
                        }
                        .overlay {
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        }
                }
        }
    }
}
