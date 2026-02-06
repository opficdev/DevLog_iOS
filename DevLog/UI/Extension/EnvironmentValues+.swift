//
//  EnvironmentValues+.swift
//  DevLog
//
//  Created by 최윤진 on 2/6/26.
//

import SwiftUI

extension EnvironmentValues {

    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }

    private struct SafeAreaInsetsKey: EnvironmentKey {
        static var defaultValue: EdgeInsets {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
                return EdgeInsets()
            }
            return window.safeAreaInsets.insets
        }
    }
}

extension UIEdgeInsets {
    var insets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}
