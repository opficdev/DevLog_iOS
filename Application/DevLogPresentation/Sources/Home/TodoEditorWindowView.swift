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
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(TodoEditorWindowEvent.self) private var windowEvent
    private let value: TodoEditorWindowValue

    public init(value: TodoEditorWindowValue) {
        self.value = value
    }

    public var body: some View {
        switch value {
        case .create(let windowCategory, _):
            TodoEditorView(
                viewModel: TodoEditorViewModel(
                    category: windowCategory.todoCategory,
                    fetchPreferencesUseCase: container.resolve(FetchTodoCategoryPreferencesUseCase.self),
                    fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self)
                ),
                onSubmit: submit,
                onClose: closeWindow
            )
        case .edit(let windowTodo):
            TodoEditorView(
                viewModel: TodoEditorViewModel(
                    todo: windowTodo.todo,
                    fetchPreferencesUseCase: container.resolve(FetchTodoCategoryPreferencesUseCase.self),
                    fetchReferenceItemsUseCase: container.resolve(FetchReferenceItemsUseCase.self)
                ),
                onSubmit: submit,
                onClose: closeWindow
            )
        }
    }

    private func closeWindow() {
        dismissWindow(id: TodoEditorWindowValue.sceneId, value: value)
    }

    private func submit(_ todo: Todo) {
        windowEvent.submit(value: value, todo: todo)
    }
}
