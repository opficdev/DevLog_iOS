//
//  TodoEditorWindowDependencies.swift
//  DevLogPresentation
//
//  Created by opfic on 6/2/26.
//

import DevLogCore
import DevLogDomain

@MainActor
public struct TodoEditorWindowDependencies {
    public let todoViewModelFactory: TodoViewModelFactory
    private let windowEvent: TodoEditorWindowEvent

    public init(
        container: DIContainer,
        windowEvent: TodoEditorWindowEvent
    ) {
        self.todoViewModelFactory = TodoViewModelFactory(container: container)
        self.windowEvent = windowEvent
    }

    public func makeEditorViewModel(
        value: TodoEditorWindowValue,
        onClose: @escaping () -> Void
    ) -> TodoEditorViewModel {
        switch value {
        case .create(let windowCategory, _):
            return todoViewModelFactory.makeEditorViewModel(
                category: windowCategory.todoCategory,
                onUpsertSuccess: { todo in
                    windowEvent.submit(value: value, todo: todo)
                    onClose()
                }
            )
        case .edit(let windowTodo):
            return todoViewModelFactory.makeEditorViewModel(
                todo: windowTodo.todo,
                onUpsertSuccess: { todo in
                    windowEvent.submit(value: value, todo: todo)
                    onClose()
                }
            )
        }
    }
}
