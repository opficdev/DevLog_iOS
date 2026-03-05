//
//  NavigationBarConfigurator.swift
//  DevLog
//
//  Created by 최윤진 on 3/5/26.
//

import SwiftUI

struct NavigationBarConfigurator: UIViewControllerRepresentable {
    private let backgroundColor: UIColor

    init(_ backgroundColor: UIColor = .systemBackground) {
        self.backgroundColor = backgroundColor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if #available(iOS 26, *) { return }
        DispatchQueue.main.async {
            guard let navigationBar = uiViewController.navigationController?.navigationBar else { return }
            let coordinator = context.coordinator
            if coordinator.originalShadowColor == nil {
                coordinator.originalShadowColor = navigationBar.standardAppearance.shadowColor
                coordinator.originalBackgroundColor = navigationBar.standardAppearance.backgroundColor
            }
            Self.applyAppearance(
                to: navigationBar,
                shadowColor: .clear,
                backgroundColor: self.backgroundColor
            )
        }
    }

    static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: Coordinator) {
        if #available(iOS 26, *) { return }
        guard let navigationBar = uiViewController.navigationController?.navigationBar else { return }
        applyAppearance(
            to: navigationBar,
            shadowColor: coordinator.originalShadowColor,
            backgroundColor: coordinator.originalBackgroundColor
        )
    }

    private static func applyAppearance(
        to navigationBar: UINavigationBar,
        shadowColor: UIColor?,
        backgroundColor: UIColor?
    ) {
        let appearances = [
            navigationBar.standardAppearance,
            navigationBar.scrollEdgeAppearance,
            navigationBar.compactAppearance,
            navigationBar.compactScrollEdgeAppearance
        ]

        for appearance in appearances {
            appearance?.shadowColor = shadowColor
            appearance?.backgroundColor = backgroundColor
        }
    }

    class Coordinator {
        var originalShadowColor: UIColor?
        var originalBackgroundColor: UIColor?
    }
}
