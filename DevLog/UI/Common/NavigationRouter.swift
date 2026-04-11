//
//  NavigationRouter.swift
//  DevLog
//
//  Created by 최윤진 on 1/1/26.
//

import SwiftUI

@Observable
final class NavigationRouter {
    var path = NavigationPath()

    func push(_ element: any Hashable) {
        Task { @MainActor in
            path.append(element)
        }
    }
}
