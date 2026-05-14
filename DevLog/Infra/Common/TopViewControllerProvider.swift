//
//  TopViewControllerProvider.swift
//  DevLog
//
//  Created by 최윤진 on 2/12/26.
//

import UIKit
import DevLogDataCommon
import DevLogDataDTO
import DevLogDataProtocol

final class TopViewControllerProvider {
    @MainActor
    func topViewController() -> UIViewController? {
        guard let keyWindow = keyWindow() else {
            return nil
        }
        
        let rootController = keyWindow.rootViewController
        return topViewController(controller: rootController)
    }
    
    @MainActor
    func keyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    @MainActor
    private func topViewController(controller: UIViewController?) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }

        if let tabController = controller as? UITabBarController,
           let selectedController = tabController.selectedViewController {
            return topViewController(controller: selectedController)
        }

        if let presentedController = controller?.presentedViewController {
            return topViewController(controller: presentedController)
        }

        return controller
    }
}
