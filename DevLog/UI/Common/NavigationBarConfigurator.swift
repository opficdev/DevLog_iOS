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
            navigationBar.standardAppearance.shadowColor = .clear
            navigationBar.standardAppearance.backgroundColor = backgroundColor
            navigationBar.scrollEdgeAppearance?.shadowColor = .clear
            navigationBar.scrollEdgeAppearance?.backgroundColor = backgroundColor
            navigationBar.compactAppearance?.shadowColor = .clear
            navigationBar.compactAppearance?.backgroundColor = backgroundColor
            navigationBar.compactScrollEdgeAppearance?.shadowColor = .clear
            navigationBar.compactScrollEdgeAppearance?.backgroundColor = backgroundColor
        }
    }

    static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: Coordinator) {
        if #available(iOS 26, *) { return }
        guard let navigationBar = uiViewController.navigationController?.navigationBar else { return }
        navigationBar.standardAppearance.shadowColor = coordinator.originalShadowColor
        navigationBar.standardAppearance.backgroundColor = coordinator.originalBackgroundColor
        navigationBar.scrollEdgeAppearance?.shadowColor = coordinator.originalShadowColor
        navigationBar.scrollEdgeAppearance?.backgroundColor = coordinator.originalBackgroundColor
        navigationBar.compactAppearance?.shadowColor = coordinator.originalShadowColor
        navigationBar.compactAppearance?.backgroundColor = coordinator.originalBackgroundColor
        navigationBar.compactScrollEdgeAppearance?.shadowColor = coordinator.originalShadowColor
        navigationBar.compactScrollEdgeAppearance?.backgroundColor = coordinator.originalBackgroundColor
    }

    class Coordinator {
        var originalShadowColor: UIColor?
        var originalBackgroundColor: UIColor?
    }
}
