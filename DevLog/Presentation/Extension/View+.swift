//
//  View+.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import SwiftUI

extension View {
    var screenWidth: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        else { return UIScreen.main.bounds.width }

        return windowScene.screen.bounds.width
    }

    var screenHeight: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        else { return UIScreen.main.bounds.height }

        return windowScene.screen.bounds.height
    }
}
