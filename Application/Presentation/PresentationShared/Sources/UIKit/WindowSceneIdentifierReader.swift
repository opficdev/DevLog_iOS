//
//  WindowSceneIdentifierReader.swift
//  PresentationShared
//
//  Created by opfic on 7/27/26.
//

import SwiftUI

public struct WindowSceneIdentifierReader: UIViewRepresentable {
    private let onResolve: (String?) -> Void

    public final class Coordinator {
        private var identifier: String?

        func update(identifier: String?) -> Bool {
            guard self.identifier != identifier else { return false }
            self.identifier = identifier
            return true
        }
    }

    public init(onResolve: @escaping (String?) -> Void) {
        self.onResolve = onResolve
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        resolve(from: view, coordinator: context.coordinator)
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        resolve(from: uiView, coordinator: context.coordinator)
    }

    private func resolve(from view: UIView, coordinator: Coordinator) {
        DispatchQueue.main.async {
            let identifier = view.window?.windowScene?.session.persistentIdentifier
            guard coordinator.update(identifier: identifier) else { return }
            onResolve(identifier)
        }
    }
}
