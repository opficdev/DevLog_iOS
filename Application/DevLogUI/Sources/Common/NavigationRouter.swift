//
//  NavigationRouter.swift
//  DevLog
//
//  Created by 최윤진 on 1/1/26.
//

import SwiftUI
import DevLogDomain
import DevLogPresentation

@Observable
final class NavigationRouter<Route: Hashable> {
    var path: [Route] = []

    var root: Route? {
        path.first
    }

    var detailPath: [Route] {
        get {
            Array(path.dropFirst())
        }
        set {
            if let route = root {
                path = [route] + newValue
            } else {
                path = newValue
            }
        }
    }

    func replace(with route: Route) {
        path = [route]
    }

    func push(_ route: Route) {
        path.append(route)
    }
}
