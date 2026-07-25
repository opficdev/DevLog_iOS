//
//  UIViewController+.swift
//  PresentationShared
//
//  Created by opfic on 7/25/26.
//

import UIKit

@MainActor
extension UIViewController {
    var visibleTabBarHeight: CGFloat {
        var topViewController = self

        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }

        if let tabBarController = (topViewController as? UITabBarController) ??
            topViewController.tabBarController {
            return tabBarController.tabBar.isHidden ? .zero : tabBarController.tabBar.frame.height
        }

        for child in topViewController.children {
            let childHeight = child.visibleTabBarHeight
            if 0 < childHeight {
                return childHeight
            }
        }

        return .zero
    }
}
