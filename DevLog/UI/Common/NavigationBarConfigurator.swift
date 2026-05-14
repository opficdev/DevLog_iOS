//
//  NavigationBarConfigurator.swift
//  DevLog
//
//  Created by 최윤진 on 3/5/26.
//

import SwiftUI
import DevLogDomain
import DevLogPresentation

/// NavigationBar의 배경색을 지정하고 shadowColor를 제거하는 구조체
///
/// 기본적으로 ``UIColor/systemBackground``를 배경색으로 사용하며,
/// 자체 `NavigationStack`을 가진 뷰에서는 `alwaysVisible`을 `true`로 설정하여
/// 스크롤 위치와 관계없이 배경색이 항상 표시되도록 할 수 있다.
struct NavigationBarConfigurator: UIViewControllerRepresentable {
    private let backgroundColor: UIColor
    private let alwaysVisible: Bool

    /// 지정된 배경색으로 Configurator를 생성한다.
    ///
    /// - Parameter backgroundColor: NavigationBar에 적용할 배경색.
    init(_ backgroundColor: UIColor = .systemBackground) {
        self.backgroundColor = backgroundColor
        self.alwaysVisible = false
    }

    /// 지정된 배경색과 상시 표시 옵션으로 Configurator를 생성한다.
    ///
    /// - Parameters:
    ///   - backgroundColor: NavigationBar에 적용할 배경색.
    ///   - alwaysVisible: `true`이면 스크롤 위치와 관계없이 배경색이 항상 표시된다.
    ///     자체 `NavigationStack`을 가진 뷰에서 사용한다.
    @available(iOS, deprecated: 18, message: "iOS 18 이상에서는 alwaysVisible 파라미터가 없는 생성자를 사용한다.")
    init(_ backgroundColor: UIColor = .systemBackground, alwaysVisible: Bool) {
        self.backgroundColor = backgroundColor
        if #available(iOS 18.0, *) {
            self.alwaysVisible = false
        } else {
            self.alwaysVisible = alwaysVisible
        }
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
            if self.alwaysVisible, navigationBar.scrollEdgeAppearance == nil {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithDefaultBackground()
                navigationBar.scrollEdgeAppearance = appearance
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
