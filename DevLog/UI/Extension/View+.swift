//
//  View+.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import SwiftUI

extension View {
    var sceneWidth: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        else { return UIScreen.main.bounds.width }

        return windowScene.screen.bounds.width
    }

    var sceneHeight: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        else { return UIScreen.main.bounds.height }

        return windowScene.screen.bounds.height
    }

    var safeAreaInsets: UIEdgeInsets {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first
        else { return UIEdgeInsets.zero }

        return window.safeAreaInsets
    }

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
