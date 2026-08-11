//
//  TodoDetailPreviewModifier.swift
//  PresentationShared
//
//  Created by opfic on 8/11/26.
//

import SwiftUI
import ComposableArchitecture
import Core
import Domain

public extension View {
    func todoDetailPreview(todoId: String) -> some View {
        modifier(TodoDetailPreviewModifier(todoId: todoId))
    }
}

private struct TodoDetailPreviewModifier: ViewModifier {
    @Environment(\.diContainer) private var container
    let todoId: String

    func body(content: Content) -> some View {
        content.overlay {
            TodoDetailPreviewInteractionView(
                todoId: todoId,
                makePreview: makePreviewViewController
            )
        }
    }

    private func makePreviewViewController() -> UIViewController {
        let store = Store(
            initialState: TodoDetailFeature.State(
                todoId: todoId,
                showEditButton: false
            )
        ) {
            TodoDetailFeature()
        } withDependencies: {
            $0.fetchTodoByIdUseCase = container.resolve(FetchTodoByIdUseCase.self)
            $0.fetchReferenceItemsUseCase = container.resolve(FetchReferenceItemsUseCase.self)
        }
        return UIHostingController(rootView: TodoDetailPreviewView(store: store))
    }
}

private struct TodoDetailPreviewInteractionView: UIViewRepresentable {
    let todoId: String
    let makePreview: () -> UIViewController

    func makeCoordinator() -> TodoDetailPreviewInteractionCoordinator {
        TodoDetailPreviewInteractionCoordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isAccessibilityElement = false
        context.coordinator.update(todoId: todoId, makePreview: makePreview)
        context.coordinator.install(on: view)
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.update(todoId: todoId, makePreview: makePreview)
    }
}

private final class TodoDetailPreviewInteractionCoordinator: NSObject {
    private weak var view: UIView?
    private var contextMenuInteraction: UIContextMenuInteraction?
    private var todoId = ""
    private var makePreview: (() -> UIViewController)?

    func update(
        todoId: String,
        makePreview: @escaping () -> UIViewController
    ) {
        self.todoId = todoId
        self.makePreview = makePreview
    }

    func install(on view: UIView) {
        guard self.view !== view else { return }

        if let contextMenuInteraction {
            self.view?.removeInteraction(contextMenuInteraction)
        }

        let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
        view.addInteraction(contextMenuInteraction)
        self.view = view
        self.contextMenuInteraction = contextMenuInteraction
    }
}

extension TodoDetailPreviewInteractionCoordinator: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let makePreview else { return nil }

        let preferredContentSize = preferredContentSize(for: interaction.view)
        return UIContextMenuConfiguration(
            identifier: todoId as NSString,
            previewProvider: {
                let viewController = makePreview()
                viewController.preferredContentSize = preferredContentSize
                return viewController
            },
            actionProvider: nil
        )
    }

    private func preferredContentSize(for view: UIView?) -> CGSize {
        let bounds = view?.window?.bounds ?? view?.bounds ?? .zero
        let width = min(420, max(280, bounds.width - 32))
        let height = min(640, max(320, bounds.height * 0.7))
        return CGSize(width: width, height: height)
    }
}
