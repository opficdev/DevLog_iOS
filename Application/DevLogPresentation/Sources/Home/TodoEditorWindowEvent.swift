//
//  TodoEditorWindowEvent.swift
//  DevLogPresentation
//
//  Created by opfic on 5/31/26.
//

import Combine
import DevLogDomain

public final class TodoEditorWindowEvent {
    private let subject = PassthroughSubject<TodoEditorWindowSubmit, Never>()

    var submits: AnyPublisher<TodoEditorWindowSubmit, Never> {
        subject.eraseToAnyPublisher()
    }

    public init() { }

    func submit(
        value: TodoEditorWindowValue,
        todo: Todo
    ) {
        subject.send(TodoEditorWindowSubmit(value: value, todo: todo))
    }
}
