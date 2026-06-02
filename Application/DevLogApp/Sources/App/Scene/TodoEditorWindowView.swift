//
//  TodoEditorWindowView.swift
//  DevLog
//
//  Created by opfic on 5/31/26.
//

import SwiftUI
import DevLogPresentation
import DevLogUI

struct TodoEditorWindowView: View {
    @State private var windowScene: UIWindowScene?
    private let value: TodoEditorWindowValue
    private let dependencies: TodoEditorWindowDependencies

    init(
        value: TodoEditorWindowValue,
        dependencies: TodoEditorWindowDependencies
    ) {
        self.value = value
        self.dependencies = dependencies
    }

    var body: some View {
        Group {
            TodoEditorView(
                viewModel: dependencies.makeEditorViewModel(
                    value: value,
                    onClose: closeWindow
                ),
                todoViewModelFactory: dependencies.todoViewModelFactory,
                onClose: closeWindow
            )
        }
        .background {
            WindowSceneReader { windowScene = $0 }
        }
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
