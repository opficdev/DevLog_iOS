//
//  ProfileViewModel.swift
//  DevLog
//
//  Created by 최윤진 on 11/22/25.
//

import Foundation

final class ProfileViewModel: Store {
    struct State {
        var name: String = ""
        var email: String = ""
        var statusMessage: String = ""
        var avatarURL: URL?

        var showDoneButton: Bool = false
        var showToast: Bool = false
        var toastMessage: String = ""
        var resetButtonEnabled: Bool {
            !statusMessage.isEmpty && showDoneButton
        }
    }

    enum Action {
        case tapConfirmButton
        case tapResetStatusMessageButton
        case willUpdateStatusMessage
        case updateStatusMessage(String)
        case tapCloseToast
    }

    enum SideEffect {
        case updateStatusMessage
    }

    @Published private(set) var state = State()

    func reduce(with action: Action) -> [SideEffect] {
        switch action {
        case .tapConfirmButton:
            state.showToast = false
        case .tapResetStatusMessageButton:
            state.statusMessage = ""
        case .willUpdateStatusMessage:
            return [.updateStatusMessage]
        case .updateStatusMessage(let message):
            state.statusMessage = message
        case .tapCloseToast:
            state.showToast = false
        }
        return []
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .updateStatusMessage:
            break
        }
    }
}
