//
//  WindowSceneIdentifierReader.swift
//  PresentationShared
//
//  Created by opfic on 7/27/26.
//

import SwiftUI

public struct WindowSceneIdentifierReader: UIViewRepresentable {
    private let onResolve: (String?) -> Void

    public init(onResolve: @escaping (String?) -> Void) {
        self.onResolve = onResolve
    }

    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        resolve(from: view)
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        resolve(from: uiView)
    }

    private func resolve(from view: UIView) {
        DispatchQueue.main.async {
            onResolve(view.window?.windowScene?.session.persistentIdentifier)
        }
    }
}
