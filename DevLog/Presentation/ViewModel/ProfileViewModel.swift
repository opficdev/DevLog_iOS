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
        case onAppear
        case tapConfirmButton
        case tapResetStatusMessageButton
        case willUpdateStatusMessage
        case fetchUserData(UserProfile)
        case updateStatusMessage(String)
        case updateStatusTextFieldFocus(Bool)
        case tapCloseToast
    }

    enum SideEffect {
        case fetchUserData
        case updateStatusMessage(String)
    }

    private let fetchUserDataUseCase: FetchUserDataUseCase
    private let upsertStatusMessageUseCase: UpsertStatusMessageUseCase
    @Published private(set) var state = State()

    init(
        fetchUserDataUseCase: FetchUserDataUseCase,
        upsertStatusMessageUseCase: UpsertStatusMessageUseCase
    ) {
        self.fetchUserDataUseCase = fetchUserDataUseCase
        self.upsertStatusMessageUseCase = upsertStatusMessageUseCase
    }

    func reduce(with action: Action) -> [SideEffect] {
        var state = self.state
        switch action {
        case .onAppear:
            return [.fetchUserData]
        case .tapConfirmButton:
            state.showToast = false
        case .tapResetStatusMessageButton:
            state.statusMessage = ""
        case .fetchUserData(let profile):
            state.name = profile.name
            state.email = profile.email
            state.statusMessage = profile.statusMessage
            state.avatarURL = profile.avatarURL
        case .willUpdateStatusMessage:
            let message = self.state.statusMessage
            return [.updateStatusMessage(message)]
        case .updateStatusMessage(let message):
            state.statusMessage = message
        case .updateStatusTextFieldFocus(let focused):
            state.showDoneButton = focused
        case .tapCloseToast:
            state.showToast = false
        }
        self.state = state
        return []
    }

    func run(_ effect: SideEffect) {
        switch effect {
        case .fetchUserData:
            Task {
                let profile = try await fetchUserDataUseCase.execute()
                send(.fetchUserData(profile))
            }
        case .updateStatusMessage(let message):
            Task {
                try await upsertStatusMessageUseCase.execute(message)
            }
        }
    }
}
