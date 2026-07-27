//
//  TopViewControllerProviderTests.swift
//  InfraTests
//
//  Created by opfic on 7/26/26.
//

import Testing
import UIKit
@testable import Infra

@MainActor
struct TopViewControllerProviderTests {
    @Test("Navigation의 표시 화면을 반환한다")
    func Navigation의_표시_화면을_반환한다() {
        let rootViewController = UIViewController()
        let visibleViewController = UIViewController()
        let navigationController = UINavigationController(
            rootViewController: rootViewController
        )
        navigationController.pushViewController(
            visibleViewController,
            animated: false
        )

        let result = TopViewControllerProvider.topViewController(
            from: navigationController
        )

        #expect(result === visibleViewController)
    }

    @Test("Tab의 선택 화면을 반환한다")
    func Tab의_선택_화면을_반환한다() {
        let firstViewController = UIViewController()
        let selectedViewController = UIViewController()
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [
            firstViewController,
            selectedViewController
        ]
        tabBarController.selectedViewController = selectedViewController

        let result = TopViewControllerProvider.topViewController(
            from: tabBarController
        )

        #expect(result === selectedViewController)
    }

    @Test("요청 scene 식별자와 일치하는 화면을 반환한다")
    func 요청_scene_식별자와_일치하는_화면을_반환한다() {
        let otherViewController = UIViewController()
        let requestedViewController = UIViewController()
        let candidates = [
            TopViewControllerProvider.Candidate(
                identifier: "other-scene",
                rootViewController: otherViewController
            ),
            TopViewControllerProvider.Candidate(
                identifier: "requested-scene",
                rootViewController: requestedViewController
            )
        ]

        let result = TopViewControllerProvider.topViewController(
            identifier: "requested-scene",
            candidates: candidates
        )

        #expect(result === requestedViewController)
    }

    @Test("요청 scene 식별자와 일치하는 화면이 없으면 nil을 반환한다")
    func 요청_scene_식별자와_일치하는_화면이_없으면_nil을_반환한다() {
        let candidates = [
            TopViewControllerProvider.Candidate(
                identifier: "other-scene",
                rootViewController: UIViewController()
            )
        ]

        let result = TopViewControllerProvider.topViewController(
            identifier: "requested-scene",
            candidates: candidates
        )

        #expect(result == nil)
    }
}
