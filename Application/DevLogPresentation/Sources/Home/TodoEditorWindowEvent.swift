//
//  TodoEditorWindowEvent.swift
//  DevLogPresentation
//
//  Created by opfic on 5/31/26.
//

import Foundation
import DevLogDomain

@MainActor
@Observable
public final class TodoEditorWindowEvent {
    var submitted: TodoEditorWindowSubmit?

    public init() { }

    func submit(
        value: TodoEditorWindowValue,
        todo: Todo
    ) {
        submitted = TodoEditorWindowSubmit(value: value, todo: todo)
    }
}
