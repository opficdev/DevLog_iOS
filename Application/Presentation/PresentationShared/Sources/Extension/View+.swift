//
//  View+.swift
//  PresentationShared
//
//  Created by 최윤진 on 11/22/25.
//

import SwiftUI

public enum AdaptiveButtonGlassEffect {
    case enabled
    case disabled
}

public extension View {
    func topBarButtonStyle(
        color: Color = .clear,
        usesTextBeforeIOS26: Bool = false,
        glassEffect: AdaptiveButtonGlassEffect = .enabled
    ) -> some View {
        modifier(TopBarButtonStyleModifier(
            color: color,
            usesTextBeforeIOS26: usesTextBeforeIOS26,
            glassEffect: glassEffect
        ))
    }

    func toolbarBackground(_ color: Color) -> some View {
        overlay(alignment: .top) {
            GeometryReader { proxy in
                color
                    .frame(height: proxy.safeAreaInsets.top)
                    .offset(y: -proxy.safeAreaInsets.top)
            }
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    func onScrollOffsetChange(action: @escaping (CGFloat) -> Void) -> some View {
        if #available(iOS 18, *) {
            self.onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y + geo.contentInsets.top
            } action: { _, newOffset in
                action(newOffset)
            }
        } else {
            self.background(ScrollViewOffsetTracker(onChange: action))
        }
    }
}

private struct ScrollViewOffsetTracker: UIViewRepresentable {
    var onChange: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onChange: onChange)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isHidden = true
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            guard let scrollView = Self.findScrollView(from: view) else { return }
            context.coordinator.observe(scrollView)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private static func findScrollView(from view: UIView) -> UIScrollView? {
        var current = view.superview
        while let superview = current {
            if let scrollView = superview as? UIScrollView {
                return scrollView
            }
            for sibling in superview.subviews where sibling !== view {
                if let scrollView = findScrollViewInSubviews(of: sibling) {
                    return scrollView
                }
            }
            current = superview.superview
        }
        return nil
    }

    private static func findScrollViewInSubviews(of view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView {
            return scrollView
        }
        for subview in view.subviews {
            if let scrollView = findScrollViewInSubviews(of: subview) {
                return scrollView
            }
        }
        return nil
    }

    class Coordinator: NSObject {
        private var onChange: (CGFloat) -> Void
        private var observation: NSKeyValueObservation?

        init(onChange: @escaping (CGFloat) -> Void) {
            self.onChange = onChange
        }

        func observe(_ scrollView: UIScrollView) {
            observation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
                let offset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
                self?.onChange(offset)
            }
        }

        deinit {
            observation?.invalidate()
        }
    }
}

public extension View {
    @ViewBuilder
    func adaptiveButtonStyle<S: InsettableShape>(
        shape: S = Capsule(),
        color: Color = .clear,
        glassEffect: AdaptiveButtonGlassEffect = .disabled
    ) -> some View {
        if #available(iOS 26.0, *) {
            switch glassEffect {
            case .enabled:
                self.foregroundStyle(Color(.label))
                    .padding(8)
                    .glassEffect(.regular.tint(color), in: shape)
                    .clipShape(shape)
            case .disabled:
                opaqueButtonStyle(shape: shape, color: color)
            }
        } else {
            opaqueButtonStyle(shape: shape, color: color)
        }
    }

    private func opaqueButtonStyle<S: InsettableShape>(
        shape: S,
        color: Color
    ) -> some View {
        self.foregroundStyle(Color(.label))
            .padding(8)
            .background {
                shape
                    .fill(color == .clear ? Color(.systemGray5) : color)
            }
            .overlay {
                if color == .clear {
                    shape
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                }
            }
    }
}

private struct TopBarButtonStyleModifier: ViewModifier {
    @ScaledMetric(relativeTo: .title) private var iconSize = UIFont.preferredFont(
        forTextStyle: .title2,
        compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
    ).lineHeight
    let color: Color
    let usesTextBeforeIOS26: Bool
    let glassEffect: AdaptiveButtonGlassEffect

    private var isIcon: Bool {
        if #available(iOS 26.0, *) {
            true
        } else {
            !usesTextBeforeIOS26
        }
    }

    func body(content: Content) -> some View {
        let label = content
            .font(isIcon ? .title2 : nil)
            .frame(width: isIcon ? iconSize : nil, height: isIcon ? iconSize : nil)

        if isIcon {
            label.adaptiveButtonStyle(shape: .circle, color: color, glassEffect: glassEffect)
        } else {
            label.adaptiveButtonStyle(color: color, glassEffect: glassEffect)
        }
    }
}
