//
//  View+Alert.swift
//  PresentationShared
//
//  Created by opfic on 7/30/26.
//

import ComposableArchitecture
import SwiftUI

public extension View {
    @preconcurrency @MainActor
    @ViewBuilder
    func prominentAlert<State, Action, AlertAction>(
        _ store: Store<State, Action>,
        state: KeyPath<State, AlertState<AlertAction>?>,
        action: CaseKeyPath<Action, PresentationAction<AlertAction>>
    ) -> some View where State: ObservableState {
        @Bindable var store = store
        let item = $store.scope(state: state, action: action)
        let alertStore = item.wrappedValue
        let alertState = store.state[keyPath: state]

        alert(
            alertState.map(\.title).map(Text.init) ?? Text(verbatim: ""),
            isPresented: Binding(item),
            presenting: alertState,
            actions: { alertState in
                ForEach(alertState.buttons) { button in
                    let usesDefaultAction = alertState.usesDefaultAction(for: button)

                    Button(
                        role: alertState.buttonRole(for: button),
                        action: {
                            button.withAction { action in
                                if let action {
                                    alertStore?.send(action)
                                }
                            }
                        }
                    ) {
                        Text(button.label)
                    }
                    .keyboardShortcut(
                        usesDefaultAction ? .defaultAction : nil
                    )
                }
            },
            message: {
                $0.message.map(Text.init)
            }
        )
    }
}

extension AlertState {
    func buttonRole(for button: ButtonState<Action>) -> ButtonRole? {
        if #available(iOS 26, *), usesDefaultAction(for: button) { return .confirm }
        if buttons.count == 1 { return nil }
        return button.role.map(ButtonRole.init)
    }

    func usesDefaultAction(for button: ButtonState<Action>) -> Bool {
        guard 1 < buttons.count else { return true }
        return buttons.first { $0.role == .destructive }?.id == button.id
    }
}
