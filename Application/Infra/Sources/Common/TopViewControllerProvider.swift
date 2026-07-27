//
//  TopViewControllerProvider.swift
//  Infra
//
//  Created by opfic on 7/26/26.
//

import UIKit

enum TopViewControllerProvider {
    struct Candidate {
        let identifier: String
        let rootViewController: UIViewController?
    }

    @MainActor
    static func topViewController(identifier: String) -> UIViewController? {
        let candidates = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .map {
                Candidate(
                    identifier: $0.session.persistentIdentifier,
                    rootViewController: $0.windows
                        .first(where: \.isKeyWindow)?
                        .rootViewController
                )
            }

        return topViewController(
            identifier: identifier,
            candidates: candidates
        )
    }

    @MainActor
    static func topViewController(
        identifier: String,
        candidates: [Candidate]
    ) -> UIViewController? {
        let rootViewController = candidates
            .first {
                $0.identifier == identifier
            }?
            .rootViewController
        return topViewController(from: rootViewController)
    }

    @MainActor
    static func topViewController(from viewController: UIViewController?) -> UIViewController? {
        if let navigationController = viewController as? UINavigationController {
            return topViewController(from: navigationController.visibleViewController)
        }

        if let tabBarController = viewController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return topViewController(from: selectedViewController)
        }

        if let presentedViewController = viewController?.presentedViewController {
            return topViewController(from: presentedViewController)
        }

        return viewController
    }
}
