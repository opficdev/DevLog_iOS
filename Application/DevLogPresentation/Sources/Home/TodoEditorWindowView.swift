//
//  TodoEditorWindowView.swift
//  DevLogPresentation
//
//  Created by opfic on 5/31/26.
//

import SwiftUI
import DevLogCore
import DevLogDomain

public struct TodoEditorWindowView: View {
    @Environment(\.diContainer) private var container: DIContainer
    @Environment(TodoEditorWindowEvent.self) private var windowEvent
    @State private var windowScene: UIWindowScene?
    private let value: TodoEditorWindowValue

    public init(value: TodoEditorWindowValue) {
        self.value = value
    }

    public var body: some View {
        Group {
            switch value {
            case .create(let windowCategory, _):
                TodoEditorView(
                    viewModel: TodoEditorViewModel(
                        category: windowCategory.todoCategory,
                        fetchPreferencesUseCase: container.resolve(FetchTodoCategoryPreferencesUseCase.self),
                        fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
                        upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
                        trackAnalyticsEventUseCase: container.resolve(TrackAnalyticsEventUseCase.self),
                        onUpsertSuccess: upsert
                    ),
                    onClose: closeWindow
                )
            case .edit(let windowTodo):
                TodoEditorView(
                    viewModel: TodoEditorViewModel(
                        todo: windowTodo.todo,
                        fetchPreferencesUseCase: container.resolve(FetchTodoCategoryPreferencesUseCase.self),
                        fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self),
                        upsertTodoUseCase: container.resolve(UpsertTodoUseCase.self),
                        onUpsertSuccess: upsert
                    ),
                    onClose: closeWindow
                )
            }
        }
        .background {
            WindowSceneReader { windowScene = $0 }
        }
    }

    private func upsert(_ todo: Todo) {
        windowEvent.submit(value: value, todo: todo)
        closeWindow()
    }

    private func closeWindow() {
        guard let windowScene else { return }
        UIApplication.shared.requestSceneSessionDestruction(
            windowScene.session,
            options: nil,
            errorHandler: nil
        )
    }
}

private struct WindowSceneReader: UIViewRepresentable {
    let onResolve: (UIWindowScene?) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        resolve(from: view)
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        resolve(from: view)
    }

    private func resolve(from view: UIView) {
        DispatchQueue.main.async {
            onResolve(view.window?.windowScene)
        }
    }
}
