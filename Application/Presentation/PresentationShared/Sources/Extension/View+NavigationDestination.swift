//
//  View+NavigationDestination.swift
//  PresentationShared
//
//  Created by opfic on 9/25/26.
//

import SwiftUI
import SwiftUINavigation
import UIComposable

public extension View {
    func navigationDestination<Item, Destination: View>(
        item: Binding<Item?>,
        interactivePop: Bool,
        @ViewBuilder destination: @escaping (Item) -> Destination
    ) -> some View {
        navigationDestination(item: item) { value in
            destination(value)
                .background {
                    if interactivePop {
                        NavigationPopGestureController()
                            .composable { controller in
                                controller.onInteractivePopCompleted = {
                                    guard item.wrappedValue != nil else { return }
                                    item.wrappedValue = nil
                                }
                            }
                    }
                }
        }
    }

    func navigationDestination<Destination: View>(
        isPresented: Binding<Bool>,
        interactivePop: Bool,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        navigationDestination(isPresented: isPresented) {
            destination()
                .background {
                    if interactivePop {
                        NavigationPopGestureController()
                            .composable { controller in
                                controller.onInteractivePopCompleted = {
                                    guard isPresented.wrappedValue else { return }
                                    isPresented.wrappedValue = false
                                }
                            }
                    }
                }
        }
    }

    func navigationDestination<Item: Hashable, Destination: View>(
        for type: Item.Type,
        interactivePop: @escaping (Item) -> Bool,
        @ViewBuilder destination: @escaping (Item) -> Destination
    ) -> some View {
        navigationDestination(for: type) { value in
            destination(value)
                .background {
                    if interactivePop(value) {
                        NavigationPopGestureController().composable()
                    }
                }
        }
    }
}

@MainActor
private final class NavigationPopGestureController: UIViewController, UICoordinatedComposable {
    var onInteractivePopCompleted: () -> Void = { }
    private weak var coordinator: Coordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        coordinator?.configure(navigationController)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        coordinator?.configure(navigationController)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: onInteractivePopCompleted)
    }

    func connect(coordinator: Coordinator) {
        self.coordinator = coordinator
    }

    func update(coordinator: Coordinator) {
        coordinator.completion = onInteractivePopCompleted
        coordinator.configure(navigationController)
    }

    func disconnect(coordinator: Coordinator) {
        self.coordinator = nil
        coordinator.restore()
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var recognizer: UIGestureRecognizer?
        private weak var controller: UINavigationController?
        private weak var delegate: (any UIGestureRecognizerDelegate)?
        private var isObserving = false
        var completion: () -> Void

        init(completion: @escaping () -> Void) {
            self.completion = completion
        }

        func configure(_ controller: UINavigationController?) {
            guard let controller,
                  let gesture = controller.interactivePopGestureRecognizer else { return }

            if recognizer !== gesture {
                restore()
                recognizer = gesture
                delegate = gesture.delegate
                gesture.addTarget(self, action: #selector(handlePopGesture(_:)))
            }

            self.controller = controller
            gesture.delegate = self
            gesture.isEnabled = 1 < controller.viewControllers.count
        }

        func restore() {
            guard let recognizer else { return }

            recognizer.removeTarget(self, action: #selector(handlePopGesture(_:)))
            if recognizer.delegate === self {
                recognizer.delegate = delegate
            }
            self.recognizer = nil
            controller = nil
            delegate = nil
            isObserving = false
        }

        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let controller else { return false }
            return 1 < controller.viewControllers.count
                && controller.transitionCoordinator == nil
        }

        @objc
        private func handlePopGesture(_ recognizer: UIGestureRecognizer) {
            guard recognizer.state == .changed,
                  !isObserving,
                  let transition = controller?.transitionCoordinator else {
                return
            }

            isObserving = true
            transition.notifyWhenInteractionChanges { context in
                self.isObserving = false
                guard !context.isCancelled else { return }
                self.completion()
            }
        }
    }
}
