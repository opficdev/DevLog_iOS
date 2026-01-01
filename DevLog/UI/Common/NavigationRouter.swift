//
//  NavigationRouter.swift
//  DevLog
//
//  Created by 최윤진 on 1/1/26.
//

import SwiftUI

final class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()

    func push(_ element: any Hashable) {
        path.append(element)
    }
}
